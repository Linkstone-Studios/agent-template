-- Analytics Views - Phase 4: A/B Testing Dashboard
-- SQL views for comparing Firebase AI vs Hermes performance

-- ============================================================================
-- Provider Cost Comparison View
-- Aggregates total cost by provider for cost analysis
-- ============================================================================
CREATE OR REPLACE VIEW ai_provider_cost_comparison AS
SELECT 
  provider,
  COUNT(*) as total_requests,
  SUM(cost_usd) as total_cost,
  AVG(cost_usd) as avg_cost_per_request,
  SUM(input_tokens + output_tokens) as total_tokens,
  AVG(input_tokens + output_tokens) as avg_tokens_per_request,
  DATE_TRUNC('day', created_at) as date
FROM ai_usage_logs
GROUP BY provider, DATE_TRUNC('day', created_at)
ORDER BY date DESC, provider;

-- ============================================================================
-- Provider Performance Comparison View
-- Aggregates latency metrics by provider for performance analysis
-- ============================================================================
CREATE OR REPLACE VIEW ai_provider_performance_comparison AS
SELECT 
  provider,
  model,
  COUNT(*) as total_requests,
  AVG(latency_ms) as avg_latency_ms,
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY latency_ms) as p50_latency_ms,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95_latency_ms,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY latency_ms) as p99_latency_ms,
  MIN(latency_ms) as min_latency_ms,
  MAX(latency_ms) as max_latency_ms,
  DATE_TRUNC('day', created_at) as date
FROM ai_performance_metrics
GROUP BY provider, model, DATE_TRUNC('day', created_at)
ORDER BY date DESC, provider;

-- ============================================================================
-- Provider Token Usage View
-- Tracks input/output token distribution by provider
-- ============================================================================
CREATE OR REPLACE VIEW ai_provider_token_usage AS
SELECT 
  provider,
  model,
  COUNT(*) as total_requests,
  SUM(input_tokens) as total_input_tokens,
  SUM(output_tokens) as total_output_tokens,
  AVG(input_tokens) as avg_input_tokens,
  AVG(output_tokens) as avg_output_tokens,
  SUM(input_tokens + output_tokens) as total_tokens,
  AVG(input_tokens + output_tokens) as avg_total_tokens,
  DATE_TRUNC('day', created_at) as date
FROM ai_performance_metrics
GROUP BY provider, model, DATE_TRUNC('day', created_at)
ORDER BY date DESC, provider;

-- ============================================================================
-- Provider Tool Usage Comparison View
-- Compares tool/function calling success rates by provider
-- ============================================================================
CREATE OR REPLACE VIEW ai_provider_tool_usage AS
SELECT 
  provider,
  COUNT(*) as total_requests,
  SUM(CASE WHEN used_tools THEN 1 ELSE 0 END) as requests_with_tools,
  ROUND(100.0 * SUM(CASE WHEN used_tools THEN 1 ELSE 0 END) / COUNT(*), 2) as tool_usage_percentage,
  DATE_TRUNC('day', created_at) as date
FROM ai_performance_metrics
GROUP BY provider, DATE_TRUNC('day', created_at)
ORDER BY date DESC, provider;

-- ============================================================================
-- Hourly Performance View (for real-time monitoring)
-- Shows performance by hour for quick anomaly detection
-- ============================================================================
CREATE OR REPLACE VIEW ai_hourly_performance AS
SELECT 
  provider,
  model,
  COUNT(*) as total_requests,
  AVG(latency_ms) as avg_latency_ms,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms) as p95_latency_ms,
  SUM(input_tokens + output_tokens) as total_tokens,
  DATE_TRUNC('hour', created_at) as hour
FROM ai_performance_metrics
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY provider, model, DATE_TRUNC('hour', created_at)
ORDER BY hour DESC, provider;

-- ============================================================================
-- User Satisfaction by Provider View
-- Aggregates user ratings and satisfaction metrics
-- (Note: This view will be populated when conversation_ratings is implemented)
-- ============================================================================
-- CREATE OR REPLACE VIEW ai_provider_satisfaction AS
-- SELECT 
--   provider,
--   COUNT(*) as total_ratings,
--   AVG(rating) as avg_rating,
--   SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) as positive_ratings,
--   SUM(CASE WHEN rating <= 2 THEN 1 ELSE 0 END) as negative_ratings,
--   ROUND(100.0 * SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) / COUNT(*), 2) as satisfaction_percentage,
--   DATE_TRUNC('day', created_at) as date
-- FROM conversation_ratings cr
-- JOIN conversations c ON c.id = cr.conversation_id
-- GROUP BY c.provider, DATE_TRUNC('day', cr.created_at)
-- ORDER BY date DESC, c.provider;

-- ============================================================================
-- Grant access to authenticated users for their own data
-- ============================================================================
GRANT SELECT ON ai_provider_cost_comparison TO authenticated;
GRANT SELECT ON ai_provider_performance_comparison TO authenticated;
GRANT SELECT ON ai_provider_token_usage TO authenticated;
GRANT SELECT ON ai_provider_tool_usage TO authenticated;
GRANT SELECT ON ai_hourly_performance TO authenticated;
-- GRANT SELECT ON ai_provider_satisfaction TO authenticated;

-- Note: These views automatically respect RLS policies from the underlying tables
-- Users will only see data for their own requests

