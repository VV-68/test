import { createClient, SupabaseClient } from 'jsr:@supabase/supabase-js@2'
import { successResponse, errorResponse, corsHeaders } from '../_shared/response.ts'
import { requireAuth, requireString } from '../_shared/validators.ts'
import { logger } from '../_shared/logger.ts'

interface RequestPayload {
  action: string;
  payload?: {
    room_id?: unknown;
    session_id?: unknown;
    new_phase?: unknown;
    is_ready?: unknown;
    distance_km?: unknown;
    budget_tier?: unknown;
    dietary_filters?: unknown;
    swipe_time_limit_minutes?: unknown;
    max_players?: unknown;
    [key: string]: unknown;
  };
}

async function verifyHost(supabaseClient: SupabaseClient, roomId: string, userId: string) {
  const { data, error } = await supabaseClient
    .from('room_members')
    .select('is_host')
    .eq('room_id', roomId)
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw new Error(`Failed to verify host: ${error.message}`)
  if (!data?.is_host) return false
  return true
}

async function getActiveSession(supabaseClient: SupabaseClient, roomId: string) {
  const { data, error } = await supabaseClient
    .from('sessions')
    .select('*')
    .eq('room_id', roomId)
    .is('completed_at', null)
    .maybeSingle()

  if (error) throw new Error(`Failed to query active session: ${error.message}`)
  return data
}

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
    const { action, payload } = (await req.json()) as RequestPayload

    switch (action) {
      case 'set_ready': {
        const roomId = requireString(payload?.room_id, 'room_id')
        const isReady = typeof payload?.is_ready === 'boolean' ? payload.is_ready : false

        const { data: memberCheck, error: memberCheckError } = await supabaseClient
          .from('room_members')
          .select('room_id')
          .eq('room_id', roomId)
          .eq('user_id', user.id)
          .maybeSingle()

        if (memberCheckError) throw new Error(`Membership check failed: ${memberCheckError.message}`)
        if (!memberCheck) return errorResponse('Not a member of this room', 403)

        const serviceClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '')

        const { data: updatedMember, error: updateError } = await serviceClient
          .from('room_members')
          .update({ is_ready: isReady })
          .eq('room_id', roomId)
          .eq('user_id', user.id)
          .select()
          .single()

        if (updateError) throw new Error(`Failed to update readiness: ${updateError.message}`)

        logger.info(`User ${user.id} set ready=${isReady} in room ${roomId}`)
        return successResponse({ member: updatedMember })
      }

      case 'update_settings': {
        const roomId = requireString(payload?.room_id, 'room_id')
        
        const isHost = await verifyHost(supabaseClient, roomId, user.id)
        if (!isHost) return errorResponse('Only the host can update settings', 403)

        let session = await getActiveSession(supabaseClient, roomId)

        if (session && session.current_phase !== 'LOBBY') {
          return errorResponse('Cannot update settings after the session has started', 400)
        }

        const distance_km = typeof payload?.distance_km === 'number' ? payload.distance_km : undefined
        const budget_tier = typeof payload?.budget_tier === 'string' ? payload.budget_tier : undefined
        const dietary_filters = Array.isArray(payload?.dietary_filters) ? payload.dietary_filters : undefined
        const swipe_time_limit_minutes = typeof payload?.swipe_time_limit_minutes === 'number' ? payload.swipe_time_limit_minutes : undefined
        const max_players = typeof payload?.max_players === 'number' ? payload.max_players : undefined

        const updates: Record<string, unknown> = {}
        if (distance_km !== undefined) updates.distance_km = distance_km
        if (budget_tier !== undefined) updates.budget_tier = budget_tier
        if (dietary_filters !== undefined) updates.dietary_filters = dietary_filters
        if (swipe_time_limit_minutes !== undefined) updates.swipe_time_limit_minutes = swipe_time_limit_minutes
        if (max_players !== undefined) updates.max_players = max_players

        if (session) {
          const { data: updatedSession, error: updateError } = await supabaseClient
            .from('sessions')
            .update(updates)
            .eq('id', session.id)
            .select()
            .single()

          if (updateError) throw new Error(`Failed to update settings: ${updateError.message}`)
          session = updatedSession
        } else {
          updates.room_id = roomId
          updates.current_phase = 'LOBBY'
          updates.created_by = user.id

          const { data: newSession, error: insertError } = await supabaseClient
            .from('sessions')
            .insert([updates])
            .select()
            .single()

          if (insertError) throw new Error(`Failed to create session settings: ${insertError.message}`)
          session = newSession
        }

        logger.info(`Session settings updated for room ${roomId}`)
        return successResponse({ session })
      }

      case 'start_session': {
        const roomId = requireString(payload?.room_id, 'room_id')

        const isHost = await verifyHost(supabaseClient, roomId, user.id)
        if (!isHost) return errorResponse('Only the host can start the session', 403)

        const { data: room, error: roomError } = await supabaseClient
          .from('rooms')
          .select('status')
          .eq('id', roomId)
          .maybeSingle()

        if (roomError) throw new Error(`Room check failed: ${roomError.message}`)
        if (!room || room.status !== 'ACTIVE') return errorResponse('Room is not active', 400)

        let session = await getActiveSession(supabaseClient, roomId)
        if (session && session.current_phase !== 'LOBBY') {
          return errorResponse('An active session is already running', 400)
        }

        const { data: members, error: membersError } = await supabaseClient
          .from('room_members')
          .select('user_id, is_ready')
          .eq('room_id', roomId)

        if (membersError) throw new Error(`Failed to fetch members: ${membersError.message}`)
        if (!members || members.length < 2) {
          return errorResponse('At least 2 members are required to start a session', 400)
        }

        const allReady = members.every(m => m.is_ready === true)
        if (!allReady) {
          return errorResponse('Not all members are ready', 400)
        }

        const now = new Date().toISOString()

        if (session) {
          const { data: updatedSession, error: updateSessionError } = await supabaseClient
            .from('sessions')
            .update({ current_phase: 'CUISINE_SWIPE', started_at: now })
            .eq('id', session.id)
            .select()
            .single()
            
          if (updateSessionError) throw new Error(`Failed to start session: ${updateSessionError.message}`)
          session = updatedSession
        } else {
          const { data: newSession, error: insertError } = await supabaseClient
            .from('sessions')
            .insert([{ room_id: roomId, current_phase: 'CUISINE_SWIPE', started_at: now, created_by: user.id }])
            .select()
            .single()

          if (insertError) throw new Error(`Failed to create and start session: ${insertError.message}`)
          session = newSession
        }

        const serviceClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '')
        const { error: resetReadyError } = await serviceClient
          .from('room_members')
          .update({ is_ready: false })
          .eq('room_id', roomId)

        if (resetReadyError) throw new Error(`Failed to reset readiness: ${resetReadyError.message}`)

        logger.info(`Session ${session.id} started in room ${roomId}`)
        return successResponse({ session })
      }

      case 'get_session': {
        const roomId = requireString(payload?.room_id, 'room_id')

        const { data: room, error: roomError } = await supabaseClient
          .from('rooms')
          .select('*')
          .eq('id', roomId)
          .maybeSingle()

        if (roomError) throw new Error(`Failed to query room: ${roomError.message}`)
        if (!room) return errorResponse('Room not found', 404)

        const { count, error: countError } = await supabaseClient
          .from('room_members')
          .select('*', { count: 'exact', head: true })
          .eq('room_id', roomId)

        if (countError) throw new Error(`Failed to count members: ${countError.message}`)

        const session = await getActiveSession(supabaseClient, roomId)

        return successResponse({ 
          session: session || null,
          room,
          member_count: count || 0
        })
      }

      case 'advance_phase': {
        const sessionId = requireString(payload?.session_id, 'session_id')
        const newPhase = requireString(payload?.new_phase, 'new_phase')

        const { data: session, error: sessionError } = await supabaseClient
          .from('sessions')
          .select('*, rooms!inner(host_id)')
          .eq('id', sessionId)
          .maybeSingle()

        if (sessionError) throw new Error(`Failed to fetch session: ${sessionError.message}`)
        if (!session) return errorResponse('Session not found', 404)

        if (session.rooms.host_id !== user.id) {
          return errorResponse('Only the host can advance the phase', 403)
        }

        const currentPhase = session.current_phase
        let valid = false

        if (currentPhase === 'LOBBY' && newPhase === 'CUISINE_SWIPE') valid = true
        if (currentPhase === 'CUISINE_SWIPE' && newPhase === 'RESTAURANT_SWIPE') valid = true
        if (currentPhase === 'RESTAURANT_SWIPE' && newPhase === 'COMPLETED') valid = true
        if (currentPhase === newPhase) valid = true

        if (!valid) {
          return errorResponse(`Invalid phase transition: ${currentPhase} -> ${newPhase}`, 400)
        }

        if (currentPhase === newPhase) {
          return successResponse({ session })
        }

        const updates: Record<string, unknown> = { current_phase: newPhase }
        if (newPhase === 'COMPLETED') {
          updates.completed_at = new Date().toISOString()
        }

        const { data: updatedSession, error: updateError } = await supabaseClient
          .from('sessions')
          .update(updates)
          .eq('id', sessionId)
          .select()
          .single()

        if (updateError) throw new Error(`Failed to advance phase: ${updateError.message}`)

        logger.info(`Session ${sessionId} advanced to ${newPhase}`)
        return successResponse({ session: updatedSession })
      }

      case 'complete_session': {
        const sessionId = requireString(payload?.session_id, 'session_id')

        const { data: sessionInfo, error: fetchError } = await supabaseClient
          .from('sessions')
          .select('rooms!inner(host_id)')
          .eq('id', sessionId)
          .maybeSingle()

        if (fetchError) throw new Error(`Failed to fetch session: ${fetchError.message}`)
        if (!sessionInfo) return errorResponse('Session not found', 404)
        if (sessionInfo.rooms.host_id !== user.id) {
          return errorResponse('Only the host can complete the session', 403)
        }

        const { data: session, error: updateError } = await supabaseClient
          .from('sessions')
          .update({ current_phase: 'COMPLETED', completed_at: new Date().toISOString() })
          .eq('id', sessionId)
          .select()
          .single()

        if (updateError) throw new Error(`Failed to complete session: ${updateError.message}`)

        logger.info(`Session ${sessionId} marked as completed`)
        return successResponse({ session })
      }

      default:
        return errorResponse(`Unknown action: ${action}`, 400)
    }

  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : 'Internal server error'
    logger.error('Session Manager Error: ' + errorMessage)
    return errorResponse(errorMessage, 500)
  }
})
