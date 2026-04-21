-- Quick fix for missing level column
-- Run this in Supabase SQL Editor

-- Add the missing level column to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS level TEXT DEFAULT 'Seed Sower';

-- Create the missing index
CREATE INDEX IF NOT EXISTS idx_profiles_level ON public.profiles(level);

-- Verify the column exists
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'profiles' AND column_name = 'level';