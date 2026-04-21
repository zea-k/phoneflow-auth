-- Clean Dashboard Test Data Seed (NO GROUPS VERSION)
-- Run: supabase db push OR psql supabase://...

BEGIN;

-- Enable RLS if not already
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;

-- Clean existing test data (no groups)
DELETE FROM user_badges WHERE user_id LIKE 'test-%';
DELETE FROM contributions WHERE user_id LIKE 'test-%';
DELETE FROM pledges WHERE user_id LIKE 'test-%';
DELETE FROM profiles WHERE id LIKE 'test-%';

-- 1. PROJECTS (ongoing - NO GROUPS)
INSERT INTO projects (id, name, description, target_amount, status, created_at) VALUES
('proj-center', 'Test Community Center', 'Modern worship/community space', 500000, 'ongoing', now()),
('proj-roof', 'Test Roof Repair', 'Church roof maintenance', 200000, 'ongoing', now())
ON CONFLICT (id) DO NOTHING;

-- 2. PROFILES (5 test users - NO group_id)
INSERT INTO profiles (id, full_name, email, phone, annual_goal, total_contributed, level, xp, streak, created_at, updated_at) VALUES
('test-admin', 'Test Super Admin', 'admin@test.com', '+255700000001', 0, 0, 'Crown Giver', 10000, 30, now(), now()),
('test-member1', 'Test John Doe', 'john@test.com', '+255700000002', 50000, 25000, 'Gold Giver', 4500, 12, now(), now()),
('test-member2', 'Test Sarah Kimani', 'sarah@test.com', '+255700000003', 30000, 18000, 'Silver Giver', 2200, 8, now(), now()),
('test-member3', 'Test James Ochieng', 'james@test.com', '+255700000004', 40000, 12000, 'Silver Giver', 1800, 5, now(), now()),
('test-member4', 'Test Mary Wanjiku', 'mary@test.com', '+255700000005', 25000, 8000, 'Bronze Giver', 800, 3, now(), now())
ON CONFLICT (id) DO NOTHING;

-- 3. CONTRIBUTIONS (real $$ data)
INSERT INTO contributions (id, user_id, project_id, amount, method, created_at) VALUES
('contrib-1', 'test-member1', 'proj-center', 10000, 'mpesa', now() - interval '2 days'),
('contrib-2', 'test-member1', NULL, 5000, 'bank_transfer', now() - interval '5 days'),
('contrib-3', 'test-member2', 'proj-center', 8000, 'mpesa', now() - interval '1 day'),
('contrib-4', 'test-member2', NULL, 3000, 'mpesa', now() - interval '3 days'),
('contrib-5', 'test-member3', 'proj-roof', 6000, 'bank_transfer', now() - interval '7 days'),
('contrib-6', 'test-member3', NULL, 4000, 'mpesa', now() - interval '10 days'),
('contrib-7', 'test-member4', NULL, 2000, 'cash', now() - interval '4 days'),
('contrib-8', 'test-member4', 'proj-center', 4000, 'mpesa', now() - interval '6 days')
ON CONFLICT (id) DO NOTHING;

-- Update total_contributed (denormalized field)
UPDATE profiles SET total_contributed = (
  SELECT COALESCE(SUM(amount), 0)
  FROM contributions 
  WHERE user_id = profiles.id
) WHERE id LIKE 'test-%';

-- Verify RPC works (NO GROUPS)
SELECT get_public_dashboard();

COMMIT;

