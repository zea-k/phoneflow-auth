-- TEST SCRIPT - Run after applying the migration
-- This will verify all tables, policies, and relationships work

-- 1. Check all tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('profiles', 'groups', 'pledges', 'contributions', 'projects', 'badges', 'user_badges', 'user_roles', 'otp_codes');

-- 2. Check profiles has level column
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'profiles' AND column_name = 'level';

-- 3. Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'groups', 'pledges', 'contributions', 'projects', 'badges', 'user_badges', 'user_roles');

-- 4. Test RPC function (should not error)
SELECT get_public_dashboard();

-- 5. Check relationships work
-- This should work without errors
SELECT p.*, g.name as group_name
FROM profiles p
LEFT JOIN groups g ON p.group_id = g.id
LIMIT 1;

-- 6. Check badges exist
SELECT COUNT(*) as badge_count FROM badges;

-- 7. Test a simple authenticated query pattern
-- (This would work when user is authenticated)
-- SELECT * FROM profiles WHERE id = auth.uid();</content>
<parameter name="filePath">/workspaces/phoneflow-auth/test_database.sql