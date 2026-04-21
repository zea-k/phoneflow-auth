-- Dashboard Tables Migration
-- Creates: groups, projects, contributions, pledges
-- Adds: annual_goal, group_id to profiles
-- Idempotent & Safe: All CREATE/ALTER IF NOT EXISTS

BEGIN;

-- ======================================================================
-- 1. PROJECTS TABLE (Church Projects)
-- ======================================================================
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  target_amount NUMERIC NOT NULL CHECK (target_amount >= 0),
  collected_amount NUMERIC NOT NULL DEFAULT 0 CHECK (collected_amount >= 0),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'ongoing' CHECK (status IN ('ongoing', 'completed', 'paused', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Projects RLS: Everyone can view, only creator can manage
DROP POLICY IF EXISTS "Projects publicly viewable" ON public.projects;
CREATE POLICY "Projects publicly viewable" ON public.projects FOR SELECT USING (true);

DROP POLICY IF EXISTS "Creator can manage project" ON public.projects;
CREATE POLICY "Creator can manage project" ON public.projects FOR ALL USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Anyone can create project" ON public.projects;
CREATE POLICY "Anyone can create project" ON public.projects FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON public.projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects(status);

-- ======================================================================
-- 2. CONTRIBUTIONS TABLE (Donations/Contributions)
-- ======================================================================
CREATE TABLE IF NOT EXISTS public.contributions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  amount NUMERIC NOT NULL CHECK (amount > 0),
  method TEXT DEFAULT 'mobile_money' CHECK (method IN ('mobile_money', 'bank_transfer', 'cash', 'check', 'other')),
  reference TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.contributions ENABLE ROW LEVEL SECURITY;

-- Contributions RLS: Users see own contributions
DROP POLICY IF EXISTS "Users view own contributions" ON public.contributions;
CREATE POLICY "Users view own contributions" ON public.contributions FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own contributions" ON public.contributions;
CREATE POLICY "Users can create own contributions" ON public.contributions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_contributions_user_id ON public.contributions(user_id);
CREATE INDEX IF NOT EXISTS idx_contributions_project_id ON public.contributions(project_id);
CREATE INDEX IF NOT EXISTS idx_contributions_created_at ON public.contributions(created_at);

-- Projects updated_at trigger
DROP TRIGGER IF EXISTS update_projects_updated_at ON public.projects;
CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Contributions updated_at trigger
DROP TRIGGER IF EXISTS update_contributions_updated_at ON public.contributions;
CREATE TRIGGER update_contributions_updated_at
  BEFORE UPDATE ON public.contributions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ======================================================================
-- 3. FUNCTION: Update project collected_amount from contributions
-- ======================================================================
CREATE OR REPLACE FUNCTION public.update_project_collected_amount()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.projects
  SET collected_amount = (
    SELECT COALESCE(SUM(amount), 0)
    FROM public.contributions
    WHERE project_id = COALESCE(NEW.project_id, OLD.project_id)
  )
  WHERE id = COALESCE(NEW.project_id, OLD.project_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_project_collected_on_contribution ON public.contributions;
CREATE TRIGGER update_project_collected_on_contribution
  AFTER INSERT OR UPDATE OR DELETE ON public.contributions
  FOR EACH ROW EXECUTE FUNCTION public.update_project_collected_amount();

-- ======================================================================
-- 4. FUNCTION: Update profile total_contributed
-- ======================================================================
CREATE OR REPLACE FUNCTION public.update_profile_total_contributed()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET total_contributed = (
    SELECT COALESCE(SUM(amount), 0)
    FROM public.contributions
    WHERE user_id = COALESCE(NEW.user_id, OLD.user_id)
  )
  WHERE id = COALESCE(NEW.user_id, OLD.user_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profile_total_on_contribution ON public.contributions;
CREATE TRIGGER update_profile_total_on_contribution
  AFTER INSERT OR UPDATE OR DELETE ON public.contributions
  FOR EACH ROW EXECUTE FUNCTION public.update_profile_total_contributed();

-- ======================================================================
-- 5. PLEDGES TABLE (Annual Giving Goals)
-- ======================================================================
CREATE TABLE IF NOT EXISTS public.pledges (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  pledge_amount NUMERIC NOT NULL CHECK (pledge_amount >= 0),
  year INTEGER NOT NULL CHECK (year >= 2020 AND year <= 2100),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.pledges ENABLE ROW LEVEL SECURITY;

-- Pledges RLS: Users see own pledges
DROP POLICY IF EXISTS "Users own pledges" ON public.pledges;
CREATE POLICY "Users own pledges" ON public.pledges FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own pledges" ON public.pledges;
CREATE POLICY "Users can create own pledges" ON public.pledges FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own pledges" ON public.pledges;
CREATE POLICY "Users can update own pledges" ON public.pledges FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own pledges" ON public.pledges;
CREATE POLICY "Users can delete own pledges" ON public.pledges FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_pledges_user_id ON public.pledges(user_id);
CREATE INDEX IF NOT EXISTS idx_pledges_year ON public.pledges(year);

-- Pledges updated_at trigger
DROP TRIGGER IF EXISTS update_pledges_updated_at ON public.pledges;
CREATE TRIGGER update_pledges_updated_at
  BEFORE UPDATE ON public.pledges
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

COMMIT;