CREATE OR REPLACE FUNCTION public.get_public_dashboard()
RETURNS jsonb AS $$
DECLARE
  total_collected NUMERIC := 0;
  active_members INT := 0;
  current_project JSONB;
BEGIN
  -- Totals (simple)
  SELECT 
    COALESCE(SUM(amount), 0),
    COUNT(DISTINCT user_id)
  INTO total_collected, active_members
  FROM public.contributions;

  -- Current project (simple)
  SELECT jsonb_build_object(
    'name', p.name,
    'description', p.description,
    'target_amount', p.target_amount,
    'collected_amount', COALESCE(SUM(c.amount), 0),
    'status', p.status
  )
  INTO current_project
  FROM public.projects p
  LEFT JOIN public.contributions c ON c.project_id = p.id
  WHERE p.status = 'ongoing'
  GROUP BY p.id, p.name, p.description, p.target_amount, p.status
  ORDER BY p.created_at DESC
  LIMIT 1;

  RETURN jsonb_build_object(
    'total_collected', total_collected,
    'active_members', active_members,
    'current_project', COALESCE(current_project, '{}'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_public_dashboard() TO anon, authenticated;

COMMENT ON FUNCTION get_public_dashboard() IS 'Public dashboard aggregates for church stats (NO GROUPS)';

