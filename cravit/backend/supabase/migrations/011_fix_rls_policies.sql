-- Migration: 011_fix_rls_policies

-- 1. Fix rooms select policy to prevent room creation block
-- Allows the room host to immediately query the room even before they are added to room_members
DROP POLICY IF EXISTS rooms_select_member ON public.rooms;

CREATE POLICY rooms_select_member_or_host
  ON public.rooms FOR SELECT
  USING (is_room_member(id) OR host_id = auth.uid());

-- 2. Fix users select policy to prevent profile fetching blocks in the lobby
-- Allows all authenticated users to read basic profile information (display_name, avatar_url)
-- We expand this to all authenticated users because Postgres RLS operates at the row level, 
-- and attempting to restrict this specifically to "only users sharing an active room" 
-- creates heavy circular dependencies and performance bottlenecks on simple profile fetches.
DROP POLICY IF EXISTS users_select_own ON public.users;

CREATE POLICY users_select_authenticated
  ON public.users FOR SELECT
  TO authenticated
  USING (true);
