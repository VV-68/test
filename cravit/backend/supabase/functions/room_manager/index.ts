import { createClient, SupabaseClient } from 'jsr:@supabase/supabase-js@2'
import { successResponse, errorResponse, corsHeaders } from '../_shared/response.ts'
import { requireAuth, requireString } from '../_shared/validators.ts'
import { logger } from '../_shared/logger.ts'

interface RoomMember {
  room_id: string;
  user_id: string;
  is_host: boolean;
  joined_at: string;
}

interface RequestPayload {
  action: string;
  payload?: {
    room_id?: unknown;
    room_code?: unknown;
    target_user_id?: unknown;
    [key: string]: unknown;
  };
}

async function generateUniqueRoomCode(supabaseClient: SupabaseClient): Promise<string> {
  let isUnique = false;
  let roomCode = '';
  while (!isUnique) {
    roomCode = Math.random().toString(36).substring(2, 8).toUpperCase();
    const { data, error } = await supabaseClient
      .from('rooms')
      .select('id')
      .eq('room_code', roomCode)
      .maybeSingle();
    
    if (error) {
      throw new Error(`Error checking room code uniqueness: ${error.message}`);
    }
    
    if (!data) {
      isUnique = true;
    }
  }
  return roomCode;
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
      case 'create_room': {
        const roomCode = await generateUniqueRoomCode(supabaseClient)
        
        const { data: room, error: roomError } = await supabaseClient
          .from('rooms')
          .insert([{ room_code: roomCode, host_id: user.id }])
          .select()
          .single()
        
        if (roomError) throw new Error(`Room creation failed: ${roomError.message}`)
        if (!room) throw new Error('Room creation returned no data')

        const { error: memberError } = await supabaseClient
          .from('room_members')
          .insert([{ room_id: room.id, user_id: user.id, is_host: true }])

        if (memberError) throw new Error(`Adding host failed: ${memberError.message}`)

        logger.info(`User ${user.id} created room ${room.id}`)
        return successResponse({ room })
      }

      case 'join_room': {
        const roomCode = requireString(payload?.room_code, 'room_code')

        const { data: room, error: roomError } = await supabaseClient
          .from('rooms')
          .select('*')
          .eq('room_code', roomCode)
          .eq('status', 'ACTIVE')
          .maybeSingle()

        if (roomError) throw new Error(`Failed to query room: ${roomError.message}`)
        if (!room) return errorResponse('Room not found or not active', 404)

        const { data: existingMember, error: checkError } = await supabaseClient
          .from('room_members')
          .select('room_id')
          .eq('room_id', room.id)
          .eq('user_id', user.id)
          .maybeSingle()

        if (checkError) throw new Error(`Failed to check membership: ${checkError.message}`)
        if (existingMember) return errorResponse('User is already a member of this room', 409)

        const { error: memberError } = await supabaseClient
          .from('room_members')
          .insert([{ room_id: room.id, user_id: user.id, is_host: false }])

        if (memberError) throw new Error(`Failed to join room: ${memberError.message}`)

        const { data: members, error: membersError } = await supabaseClient
          .from('room_members')
          .select('*, users(username, display_name, avatar_url)')
          .eq('room_id', room.id)
          
        if (membersError) throw new Error(`Failed to fetch members: ${membersError.message}`)

        logger.info(`User ${user.id} joined room ${room.id}`)
        return successResponse({ room, members })
      }

      case 'leave_room': {
        const roomId = requireString(payload?.room_id, 'room_id')

        const { data: room, error: roomError } = await supabaseClient
          .from('rooms')
          .select('host_id')
          .eq('id', roomId)
          .maybeSingle()

        if (roomError) throw new Error(`Failed to fetch room details: ${roomError.message}`)
        if (!room) return errorResponse('Room not found', 404)

        const isHostLeaving = room.host_id === user.id

        const { error: deleteError } = await supabaseClient
          .from('room_members')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', user.id)

        if (deleteError) throw new Error(`Failed to leave room: ${deleteError.message}`)

        // Use service role client for room cleanup or host transfer because
        // the user has already left the room and may not have RLS permissions
        // to view remaining members or update the room.
        const serviceClient = createClient(
          supabaseUrl,
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const { data: remainingMembersData, error: fetchMembersError } = await serviceClient
          .from('room_members')
          .select('*')
          .eq('room_id', roomId)
          .order('joined_at', { ascending: true })

        if (fetchMembersError) throw new Error(`Failed to fetch remaining members: ${fetchMembersError.message}`)

        const remainingMembers = remainingMembersData as RoomMember[] | null

        if (!remainingMembers || remainingMembers.length === 0) {
          const { error: deleteRoomError } = await serviceClient.from('rooms').delete().eq('id', roomId)
          if (deleteRoomError) throw new Error(`Failed to delete empty room: ${deleteRoomError.message}`)
          logger.info(`Room ${roomId} deleted because it became empty`)
        } else if (isHostLeaving) {
          const newHost: RoomMember = remainingMembers[0]
          
          const { error: updateRoomError } = await serviceClient
            .from('rooms')
            .update({ host_id: newHost.user_id })
            .eq('id', roomId)

          if (updateRoomError) throw new Error(`Failed to update room host: ${updateRoomError.message}`)

          const { error: updateHostFlagError } = await serviceClient
            .from('room_members')
            .update({ is_host: true })
            .eq('room_id', roomId)
            .eq('user_id', newHost.user_id)

          if (updateHostFlagError) throw new Error(`Failed to update host flag: ${updateHostFlagError.message}`)

          logger.info(`Host transferred to ${newHost.user_id} in room ${roomId}`)
        }

        return successResponse({ success: true })
      }

      case 'transfer_host': {
        const roomId = requireString(payload?.room_id, 'room_id')
        const targetUserId = requireString(payload?.target_user_id, 'target_user_id')

        const { data: currentMember, error: currentMemberError } = await supabaseClient
          .from('room_members')
          .select('is_host')
          .eq('room_id', roomId)
          .eq('user_id', user.id)
          .maybeSingle()

        if (currentMemberError) throw new Error(`Failed to check membership: ${currentMemberError.message}`)
        if (!currentMember?.is_host) {
          return errorResponse('Only the host can transfer hosting rights', 403)
        }

        const { data: targetMember, error: targetMemberError } = await supabaseClient
          .from('room_members')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('user_id', targetUserId)
          .maybeSingle()

        if (targetMemberError) throw new Error(`Failed to verify target member: ${targetMemberError.message}`)
        if (!targetMember) {
          return errorResponse('Target user is not a member of this room', 404)
        }

        // Use service role client because updating host rights modifies resources
        // that require elevated privileges, and the current user might lose their
        // host-related RLS permissions mid-transaction.
        const serviceClient = createClient(
          supabaseUrl,
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const { error: updateRoomError } = await serviceClient
          .from('rooms')
          .update({ host_id: targetUserId })
          .eq('id', roomId)

        if (updateRoomError) throw new Error(`Failed to update room host: ${updateRoomError.message}`)

        const { error: demoteHostError } = await serviceClient
          .from('room_members')
          .update({ is_host: false })
          .eq('room_id', roomId)
          .eq('user_id', user.id)

        if (demoteHostError) throw new Error(`Failed to demote current host: ${demoteHostError.message}`)

        const { error: promoteHostError } = await serviceClient
          .from('room_members')
          .update({ is_host: true })
          .eq('room_id', roomId)
          .eq('user_id', targetUserId)

        if (promoteHostError) throw new Error(`Failed to promote target host: ${promoteHostError.message}`)

        logger.info(`Host transferred from ${user.id} to ${targetUserId} in room ${roomId}`)
        return successResponse({ success: true })
      }

      case 'get_room': {
        const roomId = requireString(payload?.room_id, 'room_id')

        const { data: room, error: roomError } = await supabaseClient
          .from('rooms')
          .select('*')
          .eq('id', roomId)
          .maybeSingle()

        if (roomError) throw new Error(`Failed to fetch room: ${roomError.message}`)
        if (!room) {
          return errorResponse('Room not found', 404)
        }

        const { data: members, error: membersError } = await supabaseClient
          .from('room_members')
          .select('*, users(username, display_name, avatar_url)')
          .eq('room_id', roomId)
          
        if (membersError) throw new Error(`Failed to fetch members: ${membersError.message}`)

        const { data: session, error: sessionError } = await supabaseClient
          .from('sessions')
          .select('*')
          .eq('room_id', roomId)
          .is('completed_at', null)
          .maybeSingle()
          
        if (sessionError) throw new Error(`Failed to fetch session: ${sessionError.message}`)

        return successResponse({ room, members, session: session || null })
      }

      default:
        return errorResponse(`Unknown action: ${action}`, 400)
    }

  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : 'Internal server error'
    logger.error('Room Manager Error: ' + errorMessage)
    return errorResponse(errorMessage, 500)
  }
})

