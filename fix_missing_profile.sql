-- FIX MISSING PROFILE FOR PLEDGE FK ERROR
-- Run: supabase db psql < fix_missing_profile.sql

BEGIN;

-- Check if profile already exists (by auth.users.id)
DO $$
DECLARE
  user_id_val UUID := 'c29e8583-62c6-44d5-b602-a4cefdc48a51'::UUID;
  profile_count INT;
BEGIN
  SELECT COUNT(*) INTO profile_count 
  FROM public.profiles 
  WHERE user_id = user_id_val;
  
  IF profile_count = 0 THEN
    -- Insert missing profile (id auto-generated)
    INSERT INTO public.profiles (user_id, phone, full_name)
    VALUES (user_id_val, '', 'User Profile')
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Created missing profile for user_id: %', user_id_val;
  ELSE
    RAISE NOTICE 'Profile already exists for user_id: % (count: %)', user_id_val, profile_count;
  END IF;
END $$;

-- Verify
SELECT id, user_id, full_name FROM public.profiles WHERE user_id = 'c29e8583-62c6-44d5-b602-a4cefdc48a51';

COMMIT;

