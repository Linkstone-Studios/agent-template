-- Fix RLS policy for ai_performance_metrics to allow authenticated users to insert their own metrics
-- Date: 2026-04-17

-- Drop the restrictive service_role-only INSERT policy
DROP POLICY IF EXISTS "service_role_insert_metrics" ON "ai_performance_metrics";

-- Create policy: Authenticated users can insert their own performance metrics
CREATE POLICY "users_insert_own_metrics" ON "ai_performance_metrics"
  AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Also allow service role to insert metrics (for Edge Functions that log on behalf of users)
CREATE POLICY "service_role_insert_metrics" ON "ai_performance_metrics"
  AS PERMISSIVE FOR INSERT
  TO service_role
  WITH CHECK (true);

