# 🚀 Pushing Migrations to Supabase

## What's Ready

✅ **4 New Database Tables Created:**
- `groups` - For organizing members
- `projects` - For church projects  
- `contributions` - For tracking donations
- `user_roles` - For admin management

✅ **Migration File:** `/supabase/migrations/20260324_create_dashboard_tables.sql`

✅ **Automated Triggers & Indexes:** Pre-calculated fields, RLS policies

---

## Step 1: Get Your Access Token

1. **Go to:** https://app.supabase.com/account/tokens
2. **Click:** "New token"
3. **Name it:** (e.g., "phoneflow-migrations")
4. **Copy the token** (you'll only see it once!)

---

## Step 2: Push Migrations

### Quick Way (Commands)
```bash
# Copy your token and run this:
export SUPABASE_ACCESS_TOKEN="sbp_81bf5becbc390d7e103fcf02f7eb3a396ee443dd"

# Navigate to project
cd /workspaces/phoneflow-auth

# Push the migrations
npx supabase db push
```

### Using the Script
```bash
export SUPABASE_ACCESS_TOKEN="sbp_81bf5becbc390d7e103fcf02f7eb3a396ee443dd"
chmod +x push_migrations.sh
./push_migrations.sh
```

---

## Step 3: Verify Migration Success

After pushing, you should see:
```
✓ Migrations applied successfully
```

**Verify in Supabase Dashboard:**
1. Go to: https://app.supabase.com/project/khbohprkilegmsedhbya/editor
2. Check SQL Editor → Tables
3. You should see:
   - `contributions`
   - `groups`
   - `projects`
   - `user_roles`

Or run this SQL query:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

---

## Alternative: Using SQL Editor (Manual)

If the CLI approach doesn't work:

1. Go to Supabase Dashboard
2. Open **SQL Editor**
3. Create a new query
4. Copy contents from: `/supabase/migrations/20260324_create_dashboard_tables.sql`
5. Paste into SQL Editor
6. Click **Run**

---

## What Happens Next

After migration:

✅ Users can create church projects  
✅ Users can make contributions  
✅ Projects auto-calculate progress  
✅ User profiles track total contributions  

---

## Troubleshooting

### Issue: "Access token not provided"
**Solution:**
```bash
export SUPABASE_ACCESS_TOKEN="your_real_token"
```
Make sure the token is valid and has database access permissions.

### Issue: "Project not found"
**Solution:** The `project_id` in `supabase/config.toml` should be:
```toml
project_id = "khbohprkilegmsedhbya"
```
(I already updated this for you)

### Issue: "Migration already exists"
**Solution:** This is normal - means the migration was already applied. No action needed.

### Issue: RLS Policies Error
**Solution:** All policies are idempotent (they drop old ones first). Safe to re-run.

---

## Project Info

**Project ID:** `khbohprkilegmsedhbya`  
**Supabase URL:** https://khbohprkilegmsedhbya.supabase.co  
**Dashboard:** https://app.supabase.com/project/khbohprkilegmsedhbya

---

## Testing After Migration

```sql
-- Create sample group
INSERT INTO groups (name) VALUES ('Test Group');

-- Create sample project  
INSERT INTO projects (name, target_amount, owner_id) 
VALUES ('Test Project', 100000, (SELECT id FROM profiles LIMIT 1));

-- Make sample contribution
INSERT INTO contributions (user_id, project_id, amount, method)
VALUES ((SELECT id FROM profiles LIMIT 1), 'project-id', 10000, 'mobile_money');

-- Check data
SELECT * FROM projects;
SELECT * FROM contributions;
```

---

**Status:** Migration files created and ready to push! 🎉

