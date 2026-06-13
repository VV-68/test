import { createClient } from 'jsr:@supabase/supabase-js@2'
import { successResponse, errorResponse, corsHeaders } from '../_shared/response.ts'
import { requireAuth, requireString } from '../_shared/validators.ts'
import { logger } from '../_shared/logger.ts'

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return errorResponse('Missing Authorization header', 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const geoapifyApiKey = Deno.env.get('GEOAPIFY_API_KEY') ?? ''

    if (!geoapifyApiKey) {
      throw new Error('Geoapify API key is not configured.')
    }

    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    })

    const user = await requireAuth(supabaseClient)
    const { action, payload } = await req.json()

    switch (action) {
      case 'get_restaurants': {
        const cuisine = requireString(payload?.cuisine, 'cuisine')
        
        if (typeof payload?.latitude !== 'number' || typeof payload?.longitude !== 'number') {
          return errorResponse('Latitude and longitude must be numbers', 400)
        }
        const latitude = payload.latitude
        const longitude = payload.longitude

        // 1. Check restaurant_cache
        // Use service client to read/write cache to avoid complex RLS, although schema allows authenticated users to read.
        const serviceClient = createClient(
          supabaseUrl,
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const now = new Date().toISOString()
        
        // We'll just look for an exact cuisine match near the location (e.g. within some decimal degrees)
        // For MVP, exact match or very close. Actually, schema index is on (cuisine, latitude, longitude).
        // Let's round lat/lon to 3 decimal places for caching purposes to group nearby requests.
        const roundedLat = Number(latitude.toFixed(3))
        const roundedLng = Number(longitude.toFixed(3))

        const { data: cached, error: cacheError } = await serviceClient
          .from('restaurant_cache')
          .select('*')
          .eq('cuisine', cuisine.toLowerCase())
          .eq('latitude', roundedLat)
          .eq('longitude', roundedLng)
          .gt('expires_at', now)
          .maybeSingle()

        if (cached && !cacheError) {
          logger.info(`Cache hit for ${cuisine} at ${roundedLat}, ${roundedLng}`)
          return successResponse({ restaurants: cached.response_json, source: 'cache' })
        }

        // 2. Cache miss: Call Geoapify API
        logger.info(`Cache miss for ${cuisine} at ${roundedLat}, ${roundedLng}. Calling Geoapify...`)
        
        // Example Geoapify Places API call. 
        // Note: we use categories=catering.restaurant and search by text or conditions if needed.
        // Or simply text search. We will use a standard place search.
        const radiusMeters = 5000
        const url = `https://api.geoapify.com/v2/places?categories=catering.restaurant&filter=circle:${longitude},${latitude},${radiusMeters}&text=${encodeURIComponent(cuisine)}&limit=20&apiKey=${geoapifyApiKey}`
        
        const response = await fetch(url)
        if (!response.ok) {
          throw new Error(`Geoapify API error: ${response.status} ${response.statusText}`)
        }

        const data = await response.json()
        
        // Extract relevant features
        const restaurants = (data.features || []).map((feature: any) => ({
          id: feature.properties.place_id,
          name: feature.properties.name,
          address: feature.properties.formatted,
          lat: feature.properties.lat,
          lon: feature.properties.lon,
          details: feature.properties
        })).filter((r: any) => r.name)

        // 3. Save response in cache (expires in 24 hours)
        const expiresAt = new Date()
        expiresAt.setHours(expiresAt.getHours() + 24)

        const { error: insertError } = await serviceClient
          .from('restaurant_cache')
          .insert([{
            cuisine: cuisine.toLowerCase(),
            latitude: roundedLat,
            longitude: roundedLng,
            provider: 'geoapify',
            response_json: restaurants,
            expires_at: expiresAt.toISOString()
          }])

        if (insertError) {
          logger.warn(`Failed to save to restaurant_cache: ${insertError.message}`)
        }

        return successResponse({ restaurants, source: 'api' })
      }

      default:
        return errorResponse(`Unknown action: ${action}`, 400)
    }

  } catch (err: any) {
    logger.error('Restaurant Provider Error: ' + err.message)
    return errorResponse(err.message || 'Internal server error', 500)
  }
})
