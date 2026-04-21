-- ======================================================================
-- Consolidated Schema Migration (Safe for Fresh DB)
-- Run: supabase db reset && supabase migration up
-- Idempotent: CREATE/ALTER IF NOT EXISTS
-- ======================================================================

BEGIN;

-- ======================================================================
-- 1. Drop legacy functions (if exist)
-- ======================================================================
DROP FUNCTION IF EXISTS public.generate_otp(TEXT, TEXT) CASCADE;

-- ======================================================================
-- 2. PLEDGES table + policies + indexes
-- ======================================================================
CREATE TABLE IF NOT EXISTS public.pledges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  pledge_amount NUMERIC NOT NULL CHECK (pledge_amount >= 0),
  year INTEGER NOT NULL CHECK (year >= 2020 AND year <= 2100),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.pledges ENABLE ROW LEVEL SECURITY;

-- Drop old policies
DROP POLICY IF EXISTS "Users can view own pledges" ON public.pledges;
DROP POLICY IF EXISTS "Users can create own pledges" ON public.pledges;
DROP POLICY IF EXISTS "Users can update own pledges" ON public.pledges;
DROP POLICY IF EXISTS "Users own pledges" ON public.pledges;
DROP POLICY IF EXISTS "Admins view all" ON public.pledges;

-- Create new simple user-owned policy
CREATE POLICY "Users own pledges" ON public.pledges
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_pledges_user_id ON public.pledges(user_id);
CREATE INDEX IF NOT EXISTS idx_pledges_year ON public.pledges(year);

-- ======================================================================
-- 3. OTP_CODES table
-- ======================================================================
DROP TABLE IF EXISTS public.otp_codes;
CREATE TABLE public.otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL,
  otp TEXT NOT NULL,
  verified BOOLEAN NOT NULL DEFAULT false,
  full_name TEXT,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '5 minutes'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public insert otp_codes" ON public.otp_codes
FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public select otp_codes" ON public.otp_codes
FOR SELECT USING (true);
CREATE POLICY "Allow public update otp_codes" ON public.otp_codes
FOR UPDATE USING (true);

-- ======================================================================
-- 4. PROFILES enhancements
-- ======================================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS full_name TEXT,
  ADD COLUMN IF NOT EXISTS access_token TEXT,
  ADD COLUMN IF NOT EXISTS token_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ======================================================================
-- 5. Profile auto-creation trigger (on auth.users insert)
-- ======================================================================
CREATE OR REPLACE FUNCTION public.create_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, phone)
  VALUES (NEW.id, NEW.phone);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_user_created ON auth.users;
CREATE TRIGGER on_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.create_profile();

-- ======================================================================
-- 6. Generic updated_at trigger function
-- ======================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to profiles
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'updated_at'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.triggers
      WHERE trigger_name = 'update_profiles_updated_at' AND event_object_table = 'profiles'
    ) THEN
      CREATE TRIGGER update_profiles_updated_at
      BEFORE UPDATE ON public.profiles
      FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
    END IF;
  END IF;
END $$;

-- ======================================================================
-- 7. Profiles RLS: user-owned only
-- ======================================================================
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "users_select_group_members" ON public.profiles;

CREATE POLICY "Users own profiles" ON public.profiles
FOR ALL
USING (auth.uid()::text = id::text);

COMMIT;