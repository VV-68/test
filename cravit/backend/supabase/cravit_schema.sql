-- =============================================================================
-- CRAVIT — Food Decision App
-- Production-ready PostgreSQL Schema for Supabase
-- Migration: 001_initial_schema.sql
-- =============================================================================


-- =============================================================================
-- SECTION 1: ENUM TYPES
-- =============================================================================

CREATE TYPE room_status AS ENUM (
  'ACTIVE',
  'CLOSED'
);

CREATE TYPE session_phase AS ENUM (
  'LOBBY',
  'FILTERS',
  'CUISINE_SWIPE',
  'RESTAURANT_SWIPE',
  'TIEBREAKER',
  'COMPLETED'
);

CREATE TYPE swipe_target_type AS ENUM (
  'CUISINE',
  'RESTAURANT'
);

CREATE TYPE swipe_value AS ENUM (
  'LIKE',
  'DISLIKE',
  'SUPERLIKE',
  'VETO'
);

CREATE TYPE selection_method AS ENUM (
  'UNANIMOUS',
  'TIEBREAKER',
  'RANDOM',
  'DICTATOR'
);

CREATE TYPE notification_type AS ENUM (
  'ROOM_INVITE',
  'SESSION_STARTED',
  'MATCH_FOUND',
  'MEMBER_JOINED',
  'MEMBER_LEFT',
  'SESSION_PHASE_CHANGED',
  'GENERAL'
);


-- =============================================================================
-- SECTION 2: HELPER FUNCTION — updated_at auto-trigger
-- =============================================================================

CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =============================================================================
-- SECTION 3: TABLES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1  users
--      One row per authenticated user. Mirrors auth.users via FK.
-- -----------------------------------------------------------------------------
CREATE TABLE public.users (
  id             UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username       TEXT        NOT NULL UNIQUE,
  display_name   TEXT        NOT NULL,
  avatar_url     TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT users_username_length CHECK (char_length(username) BETWEEN 3 AND 30),
  CONSTRAINT users_username_format CHECK (username ~ '^[a-zA-Z0-9_]+$')
);

CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();


-- -----------------------------------------------------------------------------
-- 3.2  rooms
--      A room groups friends together before and during a session.
-- -----------------------------------------------------------------------------
CREATE TABLE public.rooms (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code   TEXT        NOT NULL UNIQUE,
  host_id     UUID        NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  status      room_status NOT NULL DEFAULT 'ACTIVE',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT rooms_room_code_format CHECK (room_code ~ '^[A-Z0-9]{6,8}$')
);

CREATE TRIGGER set_rooms_updated_at
  BEFORE UPDATE ON public.rooms
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();


-- -----------------------------------------------------------------------------
-- 3.3  room_members
--      Junction table: which users are in which rooms.
-- -----------------------------------------------------------------------------
CREATE TABLE public.room_members (
  room_id    UUID        NOT NULL REFERENCES public.rooms(id)  ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES public.users(id)  ON DELETE CASCADE,
  is_host    BOOLEAN     NOT NULL DEFAULT FALSE,
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (room_id, user_id)
);


-- -----------------------------------------------------------------------------
-- 3.4  sessions
--      One active session per room at a time (enforced via partial unique index).
--      Tracks the current phase and selected cuisine.
-- -----------------------------------------------------------------------------
CREATE TABLE public.sessions (
  id               UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id          UUID           NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  current_phase    session_phase  NOT NULL DEFAULT 'LOBBY',
  selected_cuisine TEXT,
  started_at       TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  completed_at     TIMESTAMPTZ,

  CONSTRAINT sessions_completed_requires_phase
    CHECK (completed_at IS NULL OR current_phase = 'COMPLETED')
);

-- Enforce: only one non-completed session per room at a time
CREATE UNIQUE INDEX sessions_one_active_per_room
  ON public.sessions (room_id)
  WHERE current_phase <> 'COMPLETED';


-- -----------------------------------------------------------------------------
-- 3.5  swipes
--      Every LIKE/DISLIKE/SUPERLIKE/VETO cast by a user during a session.
--      Unique constraint prevents re-swiping same target.
-- -----------------------------------------------------------------------------
CREATE TABLE public.swipes (
  id           UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   UUID              NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  user_id      UUID              NOT NULL REFERENCES public.users(id)    ON DELETE CASCADE,
  target_type  swipe_target_type NOT NULL,
  target_id    TEXT              NOT NULL,   -- cuisine slug or restaurant external ID
  swipe_value  swipe_value       NOT NULL,
  created_at   TIMESTAMPTZ       NOT NULL DEFAULT NOW(),

  -- Prevent a user from swiping the same target twice in the same session
  CONSTRAINT swipes_unique_per_target UNIQUE (session_id, user_id, target_type, target_id)
);


-- -----------------------------------------------------------------------------
-- 3.6  matches
--      Records the final restaurant chosen for a session.
-- -----------------------------------------------------------------------------
CREATE TABLE public.matches (
  id                UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id        UUID             NOT NULL UNIQUE REFERENCES public.sessions(id) ON DELETE CASCADE,
  restaurant_id     TEXT             NOT NULL,
  restaurant_name   TEXT             NOT NULL,
  selection_method  selection_method NOT NULL,
  matched_at        TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);


-- -----------------------------------------------------------------------------
-- 3.7  restaurant_cache
--      Cached API responses (e.g. Google Places, Yelp) keyed by cuisine + location.
-- -----------------------------------------------------------------------------
CREATE TABLE public.restaurant_cache (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  cuisine       TEXT        NOT NULL,
  latitude      NUMERIC(9,6) NOT NULL,
  longitude     NUMERIC(9,6) NOT NULL,
  provider      TEXT        NOT NULL,
  response_json JSONB       NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at    TIMESTAMPTZ NOT NULL,

  CONSTRAINT restaurant_cache_expires_after_creation
    CHECK (expires_at > created_at)
);


-- -----------------------------------------------------------------------------
-- 3.8  notifications
--      Push/in-app notifications for users.
-- -----------------------------------------------------------------------------
CREATE TABLE public.notifications (
  id          UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID              NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        notification_type NOT NULL,
  title       TEXT              NOT NULL,
  body        TEXT,
  is_read     BOOLEAN           NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);


-- -----------------------------------------------------------------------------
-- 3.9  wrapped_stats
--      Aggregated "Spotify Wrapped"-style stats per user.
--      One row per user; upserted by a background job or trigger.
-- -----------------------------------------------------------------------------
CREATE TABLE public.wrapped_stats (
  user_id             UUID  PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  sessions_played     INT   NOT NULL DEFAULT 0,
  matches_found       INT   NOT NULL DEFAULT 0,
  favorite_cuisine    TEXT,
  favorite_restaurant TEXT,
  superlikes_used     INT   NOT NULL DEFAULT 0,
  vetos_used          INT   NOT NULL DEFAULT 0,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_wrapped_stats_updated_at
  BEFORE UPDATE ON public.wrapped_stats
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();


-- =============================================================================
-- SECTION 4: PERFORMANCE INDEXES
-- =============================================================================

-- rooms
CREATE INDEX idx_rooms_host_id          ON public.rooms        (host_id);
CREATE INDEX idx_rooms_status           ON public.rooms        (status)          WHERE status = 'ACTIVE';
CREATE INDEX idx_rooms_room_code        ON public.rooms        (room_code);       -- already unique; explicit for planner

-- room_members
CREATE INDEX idx_room_members_user_id   ON public.room_members (user_id);

-- sessions
CREATE INDEX idx_sessions_room_id       ON public.sessions     (room_id);
CREATE INDEX idx_sessions_phase         ON public.sessions     (current_phase);

-- swipes
CREATE INDEX idx_swipes_session_id      ON public.swipes       (session_id);
CREATE INDEX idx_swipes_user_id         ON public.swipes       (user_id);
CREATE INDEX idx_swipes_session_target  ON public.swipes       (session_id, target_type, target_id);
-- Fast "did everyone swipe this target?" aggregation:
CREATE INDEX idx_swipes_session_value   ON public.swipes       (session_id, swipe_value);

-- matches
CREATE INDEX idx_matches_session_id     ON public.matches      (session_id);     -- already unique; explicit
CREATE INDEX idx_matches_restaurant_id  ON public.matches      (restaurant_id);

-- restaurant_cache
CREATE INDEX idx_rcache_location        ON public.restaurant_cache (cuisine, latitude, longitude);
CREATE INDEX idx_rcache_expires_at      ON public.restaurant_cache (expires_at);  -- for TTL cleanup job
CREATE INDEX idx_rcache_response_gin    ON public.restaurant_cache USING GIN (response_json);

-- notifications
CREATE INDEX idx_notifications_user_id  ON public.notifications (user_id);
CREATE INDEX idx_notifications_unread   ON public.notifications (user_id)         WHERE is_read = FALSE;


-- =============================================================================
-- SECTION 5: ROW-LEVEL SECURITY (RLS)
-- =============================================================================

-- Enable RLS on every table
ALTER TABLE public.users             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_members      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swipes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurant_cache  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wrapped_stats     ENABLE ROW LEVEL SECURITY;


-- Helper: is the calling user a member of the given room?
CREATE OR REPLACE FUNCTION is_room_member(p_room_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id
      AND user_id = auth.uid()
  );
$$;

-- Helper: is the calling user the host of the given room?
CREATE OR REPLACE FUNCTION is_room_host(p_room_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.room_members
    WHERE room_id = p_room_id
      AND user_id = auth.uid()
      AND is_host = TRUE
  );
$$;


-- ── 5.1  users ────────────────────────────────────────────────────────────────
-- Users can read their own profile; no other user can read it.
CREATE POLICY users_select_own
  ON public.users FOR SELECT
  USING (id = auth.uid());

CREATE POLICY users_update_own
  ON public.users FOR UPDATE
  USING (id = auth.uid());

-- Insert is handled by the auth trigger / signup flow (service role).
-- Add a permissive insert policy only if you handle signup on the client:
-- CREATE POLICY users_insert_own
--   ON public.users FOR INSERT
--   WITH CHECK (id = auth.uid());


-- ── 5.2  rooms ────────────────────────────────────────────────────────────────
-- Any member can view a room; only the host can update or delete.
CREATE POLICY rooms_select_member
  ON public.rooms FOR SELECT
  USING (is_room_member(id));

CREATE POLICY rooms_insert_authenticated
  ON public.rooms FOR INSERT
  WITH CHECK (host_id = auth.uid());

CREATE POLICY rooms_update_host
  ON public.rooms FOR UPDATE
  USING (is_room_host(id));

CREATE POLICY rooms_delete_host
  ON public.rooms FOR DELETE
  USING (is_room_host(id));


-- ── 5.3  room_members ─────────────────────────────────────────────────────────
-- Members can see other members of their rooms.
-- Joining a room = inserting your own row.
-- Only the host (or the member themselves) can remove a member.
CREATE POLICY room_members_select
  ON public.room_members FOR SELECT
  USING (is_room_member(room_id));

CREATE POLICY room_members_insert_self
  ON public.room_members FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY room_members_delete_self_or_host
  ON public.room_members FOR DELETE
  USING (user_id = auth.uid() OR is_room_host(room_id));


-- ── 5.4  sessions ─────────────────────────────────────────────────────────────
-- Members can view; only host can insert/update sessions.
CREATE POLICY sessions_select_member
  ON public.sessions FOR SELECT
  USING (is_room_member(room_id));

CREATE POLICY sessions_insert_host
  ON public.sessions FOR INSERT
  WITH CHECK (is_room_host(room_id));

CREATE POLICY sessions_update_host
  ON public.sessions FOR UPDATE
  USING (is_room_host(room_id));


-- ── 5.5  swipes ───────────────────────────────────────────────────────────────
-- Room members can read all swipes in a session (needed for real-time consensus).
-- Users can only insert their own swipes.
CREATE POLICY swipes_select_member
  ON public.swipes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.sessions s
      WHERE s.id = session_id
        AND is_room_member(s.room_id)
    )
  );

CREATE POLICY swipes_insert_member
  ON public.swipes FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.sessions s
      WHERE s.id = session_id
        AND is_room_member(s.room_id)
    )
  );


-- ── 5.6  matches ──────────────────────────────────────────────────────────────
-- Room members can view matches; matches are written by server-side logic
-- (service role) so no INSERT policy for authenticated users.
CREATE POLICY matches_select_member
  ON public.matches FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.sessions s
      WHERE s.id = session_id
        AND is_room_member(s.room_id)
    )
  );


-- ── 5.7  restaurant_cache ─────────────────────────────────────────────────────
-- Any authenticated user can read the cache (it's not sensitive).
-- Writes are done by service-role only (edge function / backend).
CREATE POLICY rcache_select_authenticated
  ON public.restaurant_cache FOR SELECT
  TO authenticated
  USING (TRUE);


-- ── 5.8  notifications ────────────────────────────────────────────────────────
-- Users can only see and update their own notifications.
CREATE POLICY notifications_select_own
  ON public.notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY notifications_update_own
  ON public.notifications FOR UPDATE
  USING (user_id = auth.uid());


-- ── 5.9  wrapped_stats ────────────────────────────────────────────────────────
-- Users can only see their own stats.
-- Stats are written by service role / cron job.
CREATE POLICY wrapped_stats_select_own
  ON public.wrapped_stats FOR SELECT
  USING (user_id = auth.uid());


-- =============================================================================
-- SECTION 6: SUPABASE REALTIME
-- Enable realtime publication for tables that drive live UI updates.
-- =============================================================================

-- Add tables to the realtime publication (Supabase default publication)
ALTER PUBLICATION supabase_realtime ADD TABLE public.rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE public.room_members;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.swipes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;


-- =============================================================================
-- SECTION 7: CONVENIENCE VIEWS
-- =============================================================================

-- Active rooms with member count (non-security-definer; respects RLS on rooms)
CREATE OR REPLACE VIEW public.v_active_rooms AS
SELECT
  r.id,
  r.room_code,
  r.host_id,
  u.display_name  AS host_display_name,
  r.status,
  COUNT(rm.user_id) AS member_count,
  r.created_at
FROM public.rooms r
JOIN public.users u ON u.id = r.host_id
LEFT JOIN public.room_members rm ON rm.room_id = r.id
WHERE r.status = 'ACTIVE'
GROUP BY r.id, u.display_name;

-- Session summary (current phase + match status)
CREATE OR REPLACE VIEW public.v_session_summary AS
SELECT
  s.id          AS session_id,
  s.room_id,
  s.current_phase,
  s.selected_cuisine,
  s.started_at,
  s.completed_at,
  m.restaurant_name  AS matched_restaurant,
  m.selection_method AS match_method
FROM public.sessions s
LEFT JOIN public.matches m ON m.session_id = s.id;


-- =============================================================================
-- END OF MIGRATION
-- =============================================================================
