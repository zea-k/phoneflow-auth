
-- Create badges and user_badges tables
-- Run this migration to add badge system

BEGIN;

-- Create badges table
CREATE TABLE IF NOT EXISTS public.badges (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create user_badges table
CREATE TABLE IF NOT EXISTS public.user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  badge_id TEXT NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, badge_id)
);

-- Enable RLS
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

-- RLS Policies for badges (public read)
DROP POLICY IF EXISTS "Anyone can view badges" ON public.badges;

CREATE POLICY "Anyone can view badges" ON public.badges FOR SELECT USING (true);

-- RLS Policies for user_badges
DROP POLICY IF EXISTS "Users can view own badges" ON public.user_badges;

DROP POLICY IF EXISTS "Users can insert own badges" ON public.user_badges;

CREATE POLICY "Users can insert own badges" ON public.user_badges FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own badges" ON public.user_badges FOR SELECT USING (auth.uid() = user_id);

-- Insert default badges
INSERT INTO public.badges (id, name, description, icon) VALUES
  ('first', 'First Step', 'Made your first contribution', 'Star'),
  ('quarter', '25% There', 'Reached 25% of your goal', 'Flame'),
  ('half', 'Halfway Hero', 'Reached 50% of your goal', 'Target'),
  ('three-quarter', 'Almost There', 'Reached 75% of your goal', 'Rocket'),
  ('complete', 'Goal Crusher', 'Completed your annual goal!', 'Trophy'),
  ('streak7', 'Weekly Warrior', '7-day contribution streak', 'Gem'),
  ('streak30', 'Monthly Champion', '30-day contribution streak', 'Sparkles')
ON CONFLICT (id) DO NOTHING;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON public.user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge_id ON public.user_badges(badge_id);

COMMIT;