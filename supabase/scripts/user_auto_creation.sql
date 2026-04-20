-- Migration: Auto-create public.users when auth.users is created
-- This ensures every authenticated user has a profile in public.users
-- Date: 2026-04-15 (Ran 2026-04-16)

-- ============================================================================
-- TRIGGER FUNCTION: Auto-create user profile
-- ============================================================================

-- Function to handle new user creation in auth.users
-- This automatically creates a corresponding record in public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, username, full_name, avatar_url, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists (for idempotency)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger on auth.users insert
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- BACKFILL: Create public.users for existing auth.users
-- ============================================================================

-- Insert missing users from auth.users into public.users
INSERT INTO public.users (id, email, username, full_name, avatar_url, created_at, updated_at)
SELECT 
  id,
  email,
  COALESCE(raw_user_meta_data->>'username', SPLIT_PART(email, '@', 1)),
  COALESCE(raw_user_meta_data->>'full_name', ''),
  COALESCE(raw_user_meta_data->>'avatar_url', ''),
  created_at,
  updated_at
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.users)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Log the number of users synced
DO $$
DECLARE
  auth_count INTEGER;
  public_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO auth_count FROM auth.users;
  SELECT COUNT(*) INTO public_count FROM public.users;
  
  RAISE NOTICE 'Migration complete: % auth.users, % public.users', auth_count, public_count;
  
  IF auth_count != public_count THEN
    RAISE WARNING 'Mismatch: auth.users has % users but public.users has % users', auth_count, public_count;
  END IF;
END $$;

