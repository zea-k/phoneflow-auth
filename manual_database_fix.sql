-- =========================
-- DATABASE SETUP (RUN ONCE)
-- =========================

BEGIN;

-- 1. Profiles update
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS level TEXT DEFAULT 'Seed Sower';

-- 2. Badges table
CREATE TABLE IF NOT EXISTS public.badges (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. User badges
CREATE TABLE IF NOT EXISTS public.user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  badge_id TEXT NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, badge_id)
);

-- 4. Enable RLS
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

-- 5. Policies
DROP POLICY IF EXISTS "anyone_view_badges" ON public.badges;
CREATE POLICY "anyone_view_badges"
ON public.badges FOR SELECT USING (true);

DROP POLICY IF EXISTS "users_manage_own_badges" ON public.user_badges;
CREATE POLICY "users_manage_own_badges"
ON public.user_badges
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
-- **GROUP FUNCTION REMOVED** - Simple RLS (20261204 migration)
-- CREATE OR REPLACE FUNCTION public.get_current_user_group_id()...
-- 5.1. Pledges policy (self + group leader + admin) -- keeps RLS but expands allowed actors
DROP POLICY IF EXISTS "users_manage_own_pledges" ON public.pledges;
-- **GROUP PLEDGES POLICY REMOVED** - Simple user-owned (20261204)
CREATE POLICY "users_manage_own_pledges" ON public.pledges
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 6. Default badges
INSERT INTO public.badges (id, name, description, icon) VALUES
  ('first', 'First Step', 'Made your first contribution', 'Star'),
  ('quarter', '25% There', 'Reached 25% of your goal', 'Flame'),
  ('half', 'Halfway Hero', 'Reached 50% of your goal', 'Target'),
  ('three-quarter', 'Almost There', 'Reached 75% of your goal', 'Rocket'),
  ('complete', 'Goal Crusher', 'Completed your annual goal!', 'Trophy'),
  ('streak7', 'Weekly Warrior', '7-day contribution streak', 'Gem'),
  ('streak30', 'Monthly Champion', '30-day contribution streak', 'Sparkles')
ON CONFLICT (id) DO NOTHING;

-- 7. Indexes (IMPORTANT for performance)
CREATE INDEX IF NOT EXISTS idx_profiles_level ON public.profiles(level);
-- CREATE INDEX IF NOT EXISTS idx_profiles_group_id ON public.profiles(group_id);  -- REMOVED
CREATE INDEX IF NOT EXISTS idx_contributions_user_id ON public.contributions(user_id);
CREATE INDEX IF NOT EXISTS idx_contributions_amount ON public.contributions(amount);
CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON public.user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge_id ON public.user_badges(badge_id);

-- 8. RPC FUNCTION (FIXED)
CREATE OR REPLACE FUNCTION get_public_dashboard()
RETURNS jsonb AS $$
DECLARE
  result jsonb;
  current_project_data jsonb;
  project_collected numeric := 0;
BEGIN

  -- Current project
  SELECT
    jsonb_build_object(
      'id', p.id,
      'name', p.name,
      'description', p.description,
      'target_amount', p.target_amount,
      'status', p.status
    ),
    p.collected_amount
  INTO current_project_data, project_collected
  FROM projects p
  WHERE p.status = 'ongoing'
  ORDER BY p.created_at DESC
  LIMIT 1;

  IF current_project_data IS NOT NULL THEN
    current_project_data := current_project_data 
      || jsonb_build_object('collected_amount', project_collected);
  END IF;

  -- Main dashboard
  SELECT jsonb_build_object(
    'total_collected', COALESCE(SUM(c.amount), 0),
    'active_members', COALESCE(COUNT(DISTINCT c.user_id), 0)::int,

    -- Best group
    'best_group', (
      SELECT jsonb_build_object(
        'name', sub.name,
        'total', sub.total
      )
      FROM (
        SELECT 
          g.name,
          COALESCE(SUM(c2.amount), 0) AS total
        FROM groups g
        LEFT JOIN profiles p ON p.group_id = g.id
        LEFT JOIN contributions c2 ON c2.user_id = p.id
        GROUP BY g.id, g.name
        ORDER BY total DESC NULLS LAST
        LIMIT 1
      ) sub
    ),

    -- Leaderboard
    'groups_leaderboard', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', sub.id,
          'name', sub.name,
          'total', sub.total,
          'member_count', sub.member_count
        )
      )
      FROM (
        SELECT 
          g.id,
          g.name,
          COALESCE(SUM(c2.amount), 0) AS total,
          COUNT(DISTINCT p.id) AS member_count
        FROM groups g
        LEFT JOIN profiles p ON p.group_id = g.id
        LEFT JOIN contributions c2 ON c2.user_id = p.id
        GROUP BY g.id, g.name
        ORDER BY total DESC NULLS LAST
        LIMIT 5
      ) sub
    ),

    'current_project', current_project_data

  ) INTO result
  FROM contributions c;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions
GRANT EXECUTE ON FUNCTION get_public_dashboard() TO authenticated, anon;

COMMIT;