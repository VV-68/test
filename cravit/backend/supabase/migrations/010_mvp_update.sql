-- Migration: 010_mvp_update

-- USERS
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone_number text,
ADD COLUMN IF NOT EXISTS dietary_preferences text[] DEFAULT '{}';

-- ROOM_MEMBERS
ALTER TABLE public.room_members 
ADD COLUMN IF NOT EXISTS is_ready boolean DEFAULT false;

-- SESSIONS
ALTER TABLE public.sessions 
ADD COLUMN IF NOT EXISTS distance_km integer DEFAULT 5,
ADD COLUMN IF NOT EXISTS budget_tier text DEFAULT 'BELOW_250',
ADD COLUMN IF NOT EXISTS dietary_filters text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS swipe_time_limit_minutes integer DEFAULT 5,
ADD COLUMN IF NOT EXISTS max_players integer DEFAULT 2,
ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.users(id);

-- Constraints for sessions
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sessions_distance_check') THEN
        ALTER TABLE public.sessions ADD CONSTRAINT sessions_distance_check CHECK (distance_km > 0);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sessions_swipe_time_check') THEN
        ALTER TABLE public.sessions ADD CONSTRAINT sessions_swipe_time_check CHECK (swipe_time_limit_minutes > 0);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sessions_max_players_check') THEN
        ALTER TABLE public.sessions ADD CONSTRAINT sessions_max_players_check CHECK (max_players BETWEEN 2 AND 20);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sessions_budget_tier_check') THEN
        ALTER TABLE public.sessions ADD CONSTRAINT sessions_budget_tier_check CHECK (budget_tier IN ('BELOW_100', 'BELOW_250', 'BELOW_500', 'BELOW_1000', 'BELOW_2000'));
    END IF;
END $$;

-- RESTAURANTS
CREATE TABLE IF NOT EXISTS public.restaurants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    provider text NOT NULL,
    provider_id text NOT NULL,
    name text NOT NULL,
    description text,
    cuisine text,
    latitude decimal(9,6) NOT NULL,
    longitude decimal(9,6) NOT NULL,
    rating numeric(3,2),
    price_tier text,
    distance_km numeric(6,2),
    estimated_delivery_minutes integer,
    image_url text,
    swiggy_url text,
    zomato_url text,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT restaurants_provider_unique UNIQUE (provider, provider_id),
    CONSTRAINT restaurants_rating_check CHECK (rating BETWEEN 0 AND 5),
    CONSTRAINT restaurants_delivery_time_check CHECK (estimated_delivery_minutes > 0)
);

-- Trigger for restaurants updated_at
DROP TRIGGER IF EXISTS set_restaurants_updated_at ON public.restaurants;
CREATE TRIGGER set_restaurants_updated_at
    BEFORE UPDATE ON public.restaurants
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_room_members_is_ready ON public.room_members (is_ready);
CREATE INDEX IF NOT EXISTS idx_sessions_room_id ON public.sessions (room_id);
CREATE INDEX IF NOT EXISTS idx_sessions_completed_at ON public.sessions (completed_at);

CREATE INDEX IF NOT EXISTS idx_restaurants_provider ON public.restaurants (provider);
CREATE INDEX IF NOT EXISTS idx_restaurants_cuisine ON public.restaurants (cuisine);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_active ON public.restaurants (is_active);
CREATE INDEX IF NOT EXISTS idx_restaurants_location ON public.restaurants (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_restaurants_provider_id ON public.restaurants (provider_id);

-- RLS for restaurants (Assuming standard read-only for authenticated, write for service_role)
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'restaurants_select_authenticated' AND tablename = 'restaurants') THEN
        CREATE POLICY restaurants_select_authenticated ON public.restaurants FOR SELECT TO authenticated USING (TRUE);
    END IF;
END $$;
