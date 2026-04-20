import { pgTable, uuid, text, timestamp, integer, pgEnum, numeric, boolean } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
  id: uuid('id').primaryKey().notNull(),
  email: text('email').unique().notNull(),
  username: text('username').unique().notNull(),
  fullName: text('full_name'),
  avatarUrl: text('avatar_url'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
})

// Subscription status enum
export const subscriptionStatusEnum = pgEnum('subscription_status', [
  'active',
  'cancelled',
  'expired',
  'trialing'
])

// Subscriptions table
export const subscriptions = pgTable('subscriptions', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull().unique(),
  status: subscriptionStatusEnum('status').notNull(),
  planId: text('plan_id').notNull(),
  stripeSubscriptionId: text('stripe_subscription_id').unique(),
  stripeCustomerId: text('stripe_customer_id'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }),
})

// AI provider enum
export const aiProviderEnum = pgEnum('ai_provider', ['hermes', 'firebase_ai'])

// AI Usage Logs table - tracks all AI API calls for cost monitoring and analytics
export const aiUsageLogs = pgTable('ai_usage_logs', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  provider: aiProviderEnum('provider').notNull(),
  model: text('model').notNull(),
  inputTokens: integer('input_tokens'),
  outputTokens: integer('output_tokens'),
  costUsd: numeric('cost_usd', { precision: 10, scale: 6 }),
  latencyMs: integer('latency_ms'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
})

// Agent usage tracking table (legacy - consider deprecating in favor of aiUsageLogs)
export const agentUsage = pgTable('agent_usage', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  model: text('model').notNull(),
  messageCount: integer('message_count').default(1),
  tokensUsed: integer('tokens_used'),
  timestamp: timestamp('timestamp', { withTimezone: true }).defaultNow().notNull(),
})

// Deployment type enum
export const deploymentTypeEnum = pgEnum('deployment_type', ['web', 'ios', 'android'])

// Platform type enum
export const platformEnum = pgEnum('platform', ['web', 'ios', 'android'])

// App Versions table - tracks all deployed app versions
export const appVersions = pgTable('app_versions', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  version: text('version').notNull(),
  provider: aiProviderEnum('provider').notNull(),
  featureSuffix: text('feature_suffix'),
  buildNumber: integer('build_number').notNull(),
  deployedAt: timestamp('deployed_at', { withTimezone: true }).defaultNow().notNull(),
  deploymentType: deploymentTypeEnum('deployment_type').notNull(),
  gitCommitHash: text('git_commit_hash'),
  active: boolean('active').default(true),
})

// User Sessions table - tracks user sessions with version for analytics
export const userSessions = pgTable('user_sessions', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }),
  appVersion: text('app_version').notNull(),
  provider: aiProviderEnum('provider').notNull(),
  platform: platformEnum('platform').notNull(),
  sessionStart: timestamp('session_start', { withTimezone: true }).defaultNow().notNull(),
  sessionEnd: timestamp('session_end', { withTimezone: true }),
  messagesSent: integer('messages_sent').default(0),
  errorsCount: integer('errors_count').default(0),
})

// Tool executions table - tracks all tool/function calls for analytics and debugging
export const toolExecutions = pgTable('tool_executions', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  sessionId: uuid('session_id').references(() => userSessions.id, { onDelete: 'set null' }),
  toolName: text('tool_name').notNull(),
  category: text('category').notNull(),
  argsHash: text('args_hash').notNull(), // SHA256 hash of arguments for privacy
  executionTimeMs: integer('execution_time_ms').notNull(),
  success: boolean('success').notNull(),
  errorMessage: text('error_message'),
  cached: boolean('cached').default(false).notNull(),
  provider: aiProviderEnum('provider').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
})

// AI Performance Metrics table - detailed performance tracking for A/B testing
// Stores granular metrics for comparing Firebase AI vs Hermes performance
export const aiPerformanceMetrics = pgTable('ai_performance_metrics', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }),
  provider: aiProviderEnum('provider').notNull(),
  model: text('model').notNull(),
  latencyMs: integer('latency_ms').notNull(),
  inputTokens: integer('input_tokens').notNull(),
  outputTokens: integer('output_tokens').notNull(),
  usedTools: boolean('used_tools').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
})

// ============================================================================
// CONVERSATION MANAGEMENT SCHEMA
// ============================================================================
// These tables enable systematic testing of AI providers for AI tasks
// tasks by tracking conversations, prompt templates, messages, and ratings.

// Prompt templates for systematic AI testing
export const promptTemplates = pgTable('prompt_templates', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  name: text('name').notNull(),
  description: text('description'),
  systemPrompt: text('system_prompt').notNull(),
  isDefault: boolean('is_default').default(false).notNull(),
  isPublic: boolean('is_public').default(false).notNull(), // For sharing across team
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
})

// Conversations - tracks each chat session with provider/model/prompt metadata
export const conversations = pgTable('conversations', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  title: text('title'), // Auto-generated or user-provided
  provider: aiProviderEnum('provider').notNull(), // Reuse existing enum: 'hermes' or 'firebase_ai'
  model: text('model').notNull(), // e.g., 'gemini-2.0-flash-exp'
  promptTemplateId: uuid('prompt_template_id').references(() => promptTemplates.id, { onDelete: 'set null' }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  messageCount: integer('message_count').default(0).notNull(),
  isArchived: boolean('is_archived').default(false).notNull(),
})

// Message role enum
export const messageRoleEnum = pgEnum('message_role', ['user', 'assistant', 'system'])

// Chat messages - all messages in all conversations
export const chatMessages = pgTable('chat_messages', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  conversationId: uuid('conversation_id').references(() => conversations.id, { onDelete: 'cascade' }).notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  role: messageRoleEnum('role').notNull(),
  content: text('content').notNull(),
  metadata: text('metadata').default('{}'), // JSON string for attachments, tool calls, etc.
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
})

// Conversation ratings - for systematic AI quality testing
export const conversationRatings = pgTable('conversation_ratings', {
  id: uuid('id').primaryKey().defaultRandom().notNull(),
  conversationId: uuid('conversation_id').references(() => conversations.id, { onDelete: 'cascade' }).notNull(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  rating: integer('rating').notNull(), // 1-5 stars
  notes: text('notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
})
