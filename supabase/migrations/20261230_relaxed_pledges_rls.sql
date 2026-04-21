-- Relax Pledges RLS for Public/Anon Access
-- Allows guest pledges while protecting SELECT

BEGIN;

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Users own pledges" ON public.pledges;

-- 1. Public INSERT (anyone can create pledges)
CREATE POLICY "Public create pledges" ON public.pledges
FOR INSERT WITH CHECK (true);

-- 2. Public UPDATE (anyone can update any - simplified for guests)
CREATE POLICY "Public update pledges" ON public.pledges
FOR UPDATE USING (true) WITH CHECK (true);

-- 3. Authenticated SELECT (users see own)
CREATE POLICY "Users view own pledges" ON public.pledges
FOR SELECT USING (auth.uid()::text = user_id::text);

-- 4. Authenticated DELETE own
CREATE POLICY "Users delete own pledges" ON public.pledges
FOR DELETE USING (auth.uid()::text = user_id::text);

COMMIT;

