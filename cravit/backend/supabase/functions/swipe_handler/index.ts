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

    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    })

    const user = await requireAuth(supabaseClient)
    const { action, payload } = await req.json()

    switch (action) {
      case 'cuisine_swipe': {
        const sessionId = requireString(payload?.session_id, 'session_id')
        const targetId = requireString(payload?.target_id, 'target_id')
        const swipeValue = requireString(payload?.swipe_value, 'swipe_value')

        // 1. Store swipe
        const { error: swipeError } = await supabaseClient
          .from('swipes')
          .insert([{
            session_id: sessionId,
            user_id: user.id,
            target_type: 'CUISINE',
            target_id: targetId,
            swipe_value: swipeValue
          }])

        if (swipeError) {
          // Unique constraint violation check
          if (swipeError.code === '23505') {
            return errorResponse('Duplicate swipe not allowed', 400)
          }
          throw new Error(`Failed to store swipe: ${swipeError.message}`)
        }

        // 2. Count room members
        // To get room members, we need the room_id from the session
        const { data: session } = await supabaseClient
          .from('sessions')
          .select('room_id')
          .eq('id', sessionId)
          .single()

        if (!session) {
          return errorResponse('Session not found', 404)
        }

        const { count: memberCount, error: memberError } = await supabaseClient
          .from('room_members')
          .select('*', { count: 'exact', head: true })
          .eq('room_id', session.room_id)

        if (memberError) throw new Error(`Failed to count room members: ${memberError.message}`)

        // 3. Count likes for this cuisine
        const { count: likeCount, error: likeError } = await supabaseClient
          .from('swipes')
          .select('*', { count: 'exact', head: true })
          .eq('session_id', sessionId)
          .eq('target_type', 'CUISINE')
          .eq('target_id', targetId)
          .eq('swipe_value', 'LIKE') // Or SUPERLIKE if that counts, MVP assumes LIKE

        if (likeError) throw new Error(`Failed to count swipes: ${likeError.message}`)

        // 4. Check for unanimous cuisine match
        if (memberCount && likeCount && likeCount >= memberCount) {
          // We have a winner!
          // Use service client to update session to bypass RLS if caller is not host
          const serviceClient = createClient(
            supabaseUrl,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
          )

          await serviceClient
            .from('sessions')
            .update({
              selected_cuisine: targetId,
              current_phase: 'RESTAURANT_SWIPE'
            })
            .eq('id', sessionId)

          logger.info(`Session ${sessionId} matched on cuisine ${targetId}`)
        }

        return successResponse({ success: true })
      }

      case 'restaurant_swipe': {
        const sessionId = requireString(payload?.session_id, 'session_id')
        const targetId = requireString(payload?.target_id, 'target_id')
        const swipeValue = requireString(payload?.swipe_value, 'swipe_value')

        // 1. Store swipe
        const { error: swipeError } = await supabaseClient
          .from('swipes')
          .insert([{
            session_id: sessionId,
            user_id: user.id,
            target_type: 'RESTAURANT',
            target_id: targetId,
            swipe_value: swipeValue
          }])

        if (swipeError) {
          if (swipeError.code === '23505') {
            return errorResponse('Duplicate swipe not allowed', 400)
          }
          throw new Error(`Failed to store swipe: ${swipeError.message}`)
        }

        // 2. Call match_engine
        // If a user likes a restaurant, we should run the match engine.
        // It's safe to always run it or only run it on LIKE.
        if (swipeValue === 'LIKE' || swipeValue === 'SUPERLIKE') {
          // Call match_engine function via HTTP
          const serviceClient = createClient(
            supabaseUrl,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
          )

          const { error: invokeError } = await serviceClient.functions.invoke('match_engine', {
            body: { action: 'check_match', payload: { session_id: sessionId, target_id: targetId } }
          })

          if (invokeError) {
            logger.error(`Match engine invocation failed: ${invokeError.message}`)
          }
        }

        return successResponse({ success: true })
      }

      default:
        return errorResponse(`Unknown action: ${action}`, 400)
    }

  } catch (err: any) {
    logger.error('Swipe Handler Error: ' + err.message)
    return errorResponse(err.message || 'Internal server error', 500)
  }
})
