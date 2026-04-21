re-- Check what tables exist and what's missing
-- Run this in Supabase SQL Editor

-- Check all required tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('profiles', 'pledges', 'contributions', 'projects', 'badges', 'user_badges');

-- Check if level column exists
SELECT column_name FROM information_schema.columns
WHERE table_name = 'profiles' AND column_name = 'level';

-- Check if badges tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('badges', 'user_badges');