import { createClient } from 'jsr:@supabase/supabase-js@2'
import { successResponse, errorResponse, corsHeaders } from '../_shared/response.ts'
import { requireString } from '../_shared/validators.ts'
import { logger } from '../_shared/logger.ts'

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Edge functions invoked via Supabase internally usually pass auth headers
    const authHeader = req.headers.get('Authorization')
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

    // Use service role because match_engine might need to bypass RLS to read all swipes and insert match
    const serviceClient = createClient(
      supabaseUrl,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { action, payload } = await req.json()

    switch (action) {
      case 'check_match': {
        const sessionId = requireString(payload?.session_id, 'session_id')
        const targetId = requireString(payload?.target_id, 'target_id')

        // 1. Get room_id from session
        const { data: session, error: sessionError } = await serviceClient
          .from('sessions')
          .select('room_id, current_phase')
          .eq('id', sessionId)
          .single()

        if (sessionError || !session) {
          return errorResponse('Session not found', 404)
        }

        if (session.current_phase === 'COMPLETED') {
          return successResponse({ match: null, message: 'Session already completed' })
        }

        // 2. Get room members count
        const { count: memberCount, error: memberError } = await serviceClient
          .from('room_members')
          .select('*', { count: 'exact', head: true })
          .eq('room_id', session.room_id)

        if (memberError || memberCount === null) {
          throw new Error(`Failed to count room members: ${memberError?.message}`)
        }

        // 3. Get restaurant swipes
        const { count: likeCount, error: likeError } = await serviceClient
          .from('swipes')
          .select('*', { count: 'exact', head: true })
          .eq('session_id', sessionId)
          .eq('target_type', 'RESTAURANT')
          .eq('target_id', targetId)
          .in('swipe_value', ['LIKE', 'SUPERLIKE'])

        if (likeError || likeCount === null) {
          throw new Error(`Failed to count swipes: ${likeError?.message}`)
        }

        // 4. Check if everyone liked
        if (likeCount >= memberCount) {
          // We have a unanimous match!
          
          // Try to extract restaurant name from cache if possible. For MVP, we'll use a placeholder or ID.
          // Wait, actually let's just use the targetId as the name if we can't find it easily.
          const restaurantName = payload?.restaurant_name || `Restaurant ${targetId}`

          const { data: match, error: matchError } = await serviceClient
            .from('matches')
            .insert([{
              session_id: sessionId,
              restaurant_id: targetId,
              restaurant_name: restaurantName,
              selection_method: 'UNANIMOUS'
            }])
            .select()
            .single()

          if (matchError) {
            // Might have been inserted concurrently
            if (matchError.code === '23505') {
              return successResponse({ match: null, message: 'Match already exists' })
            }
            throw new Error(`Failed to create match: ${matchError.message}`)
          }

          // Update session
          const { error: updateError } = await serviceClient
            .from('sessions')
            .update({ current_phase: 'COMPLETED', completed_at: new Date().toISOString() })
            .eq('id', sessionId)

          if (updateError) {
            logger.error(`Failed to complete session: ${updateError.message}`)
          }

          logger.info(`Session ${sessionId} found UNANIMOUS match: ${targetId}`)
          return successResponse({ match })
        }

        return successResponse({ match: null })
      }

      default:
        return errorResponse(`Unknown action: ${action}`, 400)
    }

  } catch (err: any) {
    logger.error('Match Engine Error: ' + err.message)
    return errorResponse(err.message || 'Internal server error', 500)
  }
})
