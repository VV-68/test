-- Migration: 011_auth_trigger
-- Auto-syncs users created via Supabase Auth into the public.users profile table.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_username TEXT;
  new_display_name TEXT;
  base_username TEXT;
  cnt INT := 0;
BEGIN
  -- Extract display name from metadata if available, else default
  new_display_name := COALESCE(
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'username',
    'User_' || SUBSTRING(NEW.id::TEXT FROM 1 FOR 6)
  );

  -- Extract username from metadata, or use display_name, or generate from ID
  base_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    REGEXP_REPLACE(new_display_name, '[^a-zA-Z0-9_]', '', 'g')
  );
  
  -- Ensure it's not empty, otherwise default to a unique user_...
  IF base_username = '' OR base_username IS NULL THEN
    base_username := 'user_' || SUBSTRING(NEW.id::TEXT FROM 1 FOR 8);
  END IF;

  -- Trim to length constraints (between 3 and 30 characters)
  base_username := SUBSTRING(base_username FROM 1 FOR 25);
  -- Ensure it's at least 3 characters
  IF LENGTH(base_username) < 3 THEN
    base_username := base_username || 'usr';
  END IF;
  new_username := base_username;

  -- Ensure uniqueness of username in public.users
  LOOP
    SELECT COUNT(*) INTO cnt FROM public.users WHERE username = new_username;
    IF cnt = 0 THEN
      EXIT;
    END IF;
    new_username := SUBSTRING(base_username FROM 1 FOR 20) || '_' || CAST(FLOOR(RANDOM() * 1000) AS INT);
  END LOOP;

  INSERT INTO public.users (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    new_username,
    new_display_name,
    COALESCE(
      NEW.raw_user_meta_data->>'avatar_url',
      'https://api.dicebear.com/7.x/bottts/svg?seed=' || new_username
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Also ensure client-side can insert manually if needed
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'users_insert_own' AND tablename = 'users') THEN
    CREATE POLICY users_insert_own ON public.users FOR INSERT WITH CHECK (id = auth.uid());
  END IF;
END $$;
