-- ============================================================================
-- Conversation Analytics Views - Phase 6
-- Run this script via Supabase Dashboard > SQL Editor (Ran 2026-04-16)
-- ============================================================================
-- Purpose: Create analytics views for tracking AI provider performance,
--          prompt template effectiveness, and conversation quality metrics
-- ============================================================================

-- 1. Average Rating by Provider
-- Shows which AI provider (Hermes vs Firebase AI) performs best overall
CREATE OR REPLACE VIEW conversation_avg_rating_by_provider AS
SELECT 
  c.provider,
  COUNT(DISTINCT cr.conversation_id) as rated_conversations,
  AVG(cr.rating) as avg_rating,
  STDDEV(cr.rating) as rating_stddev,
  MIN(cr.rating) as min_rating,
  MAX(cr.rating) as max_rating,
  SUM(CASE WHEN cr.rating >= 4 THEN 1 ELSE 0 END) as high_ratings_count,
  SUM(CASE WHEN cr.rating <= 2 THEN 1 ELSE 0 END) as low_ratings_count,
  ROUND(100.0 * SUM(CASE WHEN cr.rating >= 4 THEN 1 ELSE 0 END) / COUNT(*), 2) as satisfaction_percentage,
  DATE_TRUNC('day', cr.created_at) as date
FROM conversation_ratings cr
JOIN conversations c ON c.id = cr.conversation_id
GROUP BY c.provider, DATE_TRUNC('day', cr.created_at)
ORDER BY date DESC, c.provider;

-- 2. Average Rating by Prompt Template
-- Shows which prompt templates produce the highest quality conversations
CREATE OR REPLACE VIEW conversation_avg_rating_by_template AS
SELECT 
  pt.id as template_id,
  pt.name as template_name,
  pt.description as template_description,
  COUNT(DISTINCT cr.conversation_id) as rated_conversations,
  AVG(cr.rating) as avg_rating,
  STDDEV(cr.rating) as rating_stddev,
  MIN(cr.rating) as min_rating,
  MAX(cr.rating) as max_rating,
  SUM(CASE WHEN cr.rating >= 4 THEN 1 ELSE 0 END) as high_ratings_count,
  SUM(CASE WHEN cr.rating <= 2 THEN 1 ELSE 0 END) as low_ratings_count,
  ROUND(100.0 * SUM(CASE WHEN cr.rating >= 4 THEN 1 ELSE 0 END) / COUNT(*), 2) as satisfaction_percentage,
  DATE_TRUNC('day', cr.created_at) as date
FROM conversation_ratings cr
JOIN conversations c ON c.id = cr.conversation_id
JOIN prompt_templates pt ON pt.id = c.prompt_template_id
WHERE c.prompt_template_id IS NOT NULL
GROUP BY pt.id, pt.name, pt.description, DATE_TRUNC('day', cr.created_at)
ORDER BY date DESC, avg_rating DESC;

-- 3. Most Used Prompt Templates
-- Shows which templates are most popular
CREATE OR REPLACE VIEW prompt_template_usage_stats AS
SELECT 
  pt.id as template_id,
  pt.name as template_name,
  pt.description as template_description,
  pt.is_public,
  COUNT(c.id) as conversation_count,
  COUNT(DISTINCT c.user_id) as unique_users,
  MAX(c.created_at) as last_used_at,
  MIN(c.created_at) as first_used_at,
  DATE_TRUNC('day', c.created_at) as date
FROM prompt_templates pt
LEFT JOIN conversations c ON c.prompt_template_id = pt.id
GROUP BY pt.id, pt.name, pt.description, pt.is_public, DATE_TRUNC('day', c.created_at)
ORDER BY conversation_count DESC, date DESC;

-- 4. Conversation Count by Provider Over Time
-- Time series data for tracking provider usage trends
CREATE OR REPLACE VIEW conversation_count_by_provider_over_time AS
SELECT 
  provider,
  model,
  COUNT(*) as conversation_count,
  COUNT(DISTINCT user_id) as unique_users,
  SUM(message_count) as total_messages,
  AVG(message_count) as avg_messages_per_conversation,
  DATE_TRUNC('day', created_at) as date,
  DATE_TRUNC('week', created_at) as week,
  DATE_TRUNC('month', created_at) as month
FROM conversations
GROUP BY provider, model, 
  DATE_TRUNC('day', created_at),
  DATE_TRUNC('week', created_at),
  DATE_TRUNC('month', created_at)
ORDER BY date DESC, provider;

-- 5. Provider x Template Performance Matrix
-- Cross-tabulation showing which provider works best with which template
CREATE OR REPLACE VIEW provider_template_performance_matrix AS
SELECT 
  c.provider,
  c.model,
  pt.id as template_id,
  pt.name as template_name,
  COUNT(DISTINCT c.id) as conversation_count,
  COUNT(DISTINCT cr.id) as rating_count,
  AVG(cr.rating) as avg_rating,
  ROUND(100.0 * SUM(CASE WHEN cr.rating >= 4 THEN 1 ELSE 0 END) / NULLIF(COUNT(cr.id), 0), 2) as satisfaction_percentage,
  AVG(c.message_count) as avg_messages_per_conversation,
  DATE_TRUNC('week', c.created_at) as week
FROM conversations c
LEFT JOIN prompt_templates pt ON pt.id = c.prompt_template_id
LEFT JOIN conversation_ratings cr ON cr.conversation_id = c.id
GROUP BY c.provider, c.model, pt.id, pt.name, DATE_TRUNC('week', c.created_at)
ORDER BY week DESC, avg_rating DESC NULLS LAST;

-- 6. User Engagement Summary
-- Per-user statistics on conversation activity and satisfaction
CREATE OR REPLACE VIEW user_conversation_engagement AS
SELECT 
  u.id as user_id,
  u.email,
  COUNT(DISTINCT c.id) as total_conversations,
  COUNT(DISTINCT cr.id) as total_ratings,
  AVG(cr.rating) as avg_rating_given,
  SUM(c.message_count) as total_messages_sent,
  AVG(c.message_count) as avg_messages_per_conversation,
  MAX(c.updated_at) as last_conversation_at,
  MIN(c.created_at) as first_conversation_at
FROM users u
LEFT JOIN conversations c ON c.user_id = u.id
LEFT JOIN conversation_ratings cr ON cr.user_id = u.id
GROUP BY u.id, u.email
ORDER BY total_conversations DESC;

-- Grant SELECT permissions to authenticated users
-- These views respect RLS from underlying tables automatically
GRANT SELECT ON conversation_avg_rating_by_provider TO authenticated;
GRANT SELECT ON conversation_avg_rating_by_template TO authenticated;
GRANT SELECT ON prompt_template_usage_stats TO authenticated;
GRANT SELECT ON conversation_count_by_provider_over_time TO authenticated;
GRANT SELECT ON provider_template_performance_matrix TO authenticated;
GRANT SELECT ON user_conversation_engagement TO authenticated;

