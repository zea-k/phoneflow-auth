#!/bin/bash
# Supabase Migration Push Script
# Instructions:
# 1. Get your access token from: https://app.supabase.com/account/tokens
# 2. Set it: export SUPABASE_ACCESS_TOKEN="your_token"
# 3. Run this script: ./push_migrations.sh

set -e

echo "🔐 Supabase Migration Push"
echo "=========================="

if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo "❌ SUPABASE_ACCESS_TOKEN not set"
    echo ""
    echo "Get your access token from:"
    echo "👉 https://app.supabase.com/account/tokens"
    echo ""
    echo "Then run:"
    echo "  export SUPABASE_ACCESS_TOKEN='your_access_token_here'"
    echo "  ./push_migrations.sh"
    exit 1
fi

echo "📁 Project: khbohprkilegmsedhbya"
echo ""

echo "📋 Checking migrations..."
npx supabase migration list --linked

echo ""
echo "🚀 Pushing migrations to Supabase..."
npx supabase db push

echo ""
echo "✅ Migrations pushed successfully!"
echo ""
echo "Verify tables in Supabase:"
echo "👉 https://app.supabase.com/project/khbohprkilegmsedhbya/editor"
