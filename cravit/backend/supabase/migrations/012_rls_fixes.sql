-- Migration: 012_rls_fixes
-- Fixes RLS SELECT policies on public.rooms and public.users to prevent creation blockers and metadata read blockers.

-- 1. Fix rooms select policy: Allow the host to select the room during insert returning block
DROP POLICY IF EXISTS rooms_select_member ON public.rooms;
CREATE POLICY rooms_select_member
  ON public.rooms FOR SELECT
  USING (is_room_member(id) OR host_id = auth.uid());

-- 2. Fix users select policy: Allow all authenticated users to read public profile details (username, display name, avatar)
DROP POLICY IF EXISTS users_select_own ON public.users;
DROP POLICY IF EXISTS users_select_all ON public.users;
CREATE POLICY users_select_all
  ON public.users FOR SELECT
  TO authenticated
  USING (TRUE);
