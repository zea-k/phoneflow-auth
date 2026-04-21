# Database Schema - NO GROUPS Version (Updated 20261204)

## Overview
Simplified user-owned database schema. **NO GROUPS** - all data user-owned with simple RLS. See 20261204_simplified_no_groups_rls_fix.sql for migration.

## Core Tables

### 1. **PROFILES**
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, auth.users |
| phone | TEXT | |
| full_name | TEXT | |
| annual_goal | NUMERIC | DEFAULT 0 |
| total_contributed | NUMERIC | DEFAULT 0 (trigger) |
| level | TEXT | DEFAULT 'Seed Sower' |
| created_at/updated_at | TIMESTAMPTZ | |

**RLS:** `auth.uid() = id` (user-owned)

### 2. **PLEDGES**
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK profiles |
| pledge_amount | NUMERIC | >0 |
| year | INTEGER | 2020-2100 |

**RLS:** `auth.uid() = user_id`

### 3. **CONTRIBUTIONS**
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK profiles |
| project_id | UUID | FK projects (optional) |
| amount | NUMERIC | >0 |
| method | TEXT | mobile_money/etc |
| reference | TEXT | |

**RLS:** `auth.uid() = user_id`

### 4. **PROJECTS** 
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| name | TEXT | NOT NULL |
| target_amount | NUMERIC | >0 |
| collected_amount | NUMERIC | trigger-updated |
| owner_id | UUID | FK profiles |
| status | TEXT | ongoing/completed |

**RLS:** Public read + `owner_id = auth.uid()`

### 5. **BADGES & USER_BADGES**
Public badges table, user-owned user_badges.

## RPC: get_public_dashboard()
Returns:
```
{
  total_collected: NUMERIC
  active_members: INT
  current_project: JSONB  
}
```
**NO groups_leaderboard/best_group**

## Status: ✅ COMPLETE - Groups Fully Removed
**Migration:** 20261204_simplified_no_groups_rls_fix.sql
