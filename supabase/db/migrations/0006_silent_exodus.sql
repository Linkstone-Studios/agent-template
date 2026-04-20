CREATE TYPE "public"."message_role" AS ENUM('user', 'assistant', 'system');--> statement-breakpoint
CREATE TABLE "chat_messages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"conversation_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"role" "message_role" NOT NULL,
	"content" text NOT NULL,
	"metadata" text DEFAULT '{}',
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "conversation_ratings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"conversation_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"rating" integer NOT NULL,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "conversations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"title" text,
	"provider" "ai_provider" NOT NULL,
	"model" text NOT NULL,
	"prompt_template_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"message_count" integer DEFAULT 0 NOT NULL,
	"is_archived" boolean DEFAULT false NOT NULL
);
--> statement-breakpoint
CREATE TABLE "prompt_templates" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"system_prompt" text NOT NULL,
	"is_default" boolean DEFAULT false NOT NULL,
	"is_public" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_conversation_id_conversations_id_fk" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "conversation_ratings" ADD CONSTRAINT "conversation_ratings_conversation_id_conversations_id_fk" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "conversation_ratings" ADD CONSTRAINT "conversation_ratings_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_prompt_template_id_prompt_templates_id_fk" FOREIGN KEY ("prompt_template_id") REFERENCES "public"."prompt_templates"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "prompt_templates" ADD CONSTRAINT "prompt_templates_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint

-- ============================================================================
-- CONSTRAINTS
-- ============================================================================

-- Unique constraint for default template per user (only one default per user)
CREATE UNIQUE INDEX unique_default_per_user
  ON "prompt_templates"(user_id)
  WHERE is_default = true;
--> statement-breakpoint

-- Unique constraint: one rating per user per conversation
ALTER TABLE "conversation_ratings"
  ADD CONSTRAINT unique_rating_per_user_per_conversation
  UNIQUE (conversation_id, user_id);
--> statement-breakpoint

-- Check constraint: rating between 1 and 5
ALTER TABLE "conversation_ratings"
  ADD CONSTRAINT rating_range_check
  CHECK (rating >= 1 AND rating <= 5);
--> statement-breakpoint

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Indexes for conversations table
CREATE INDEX idx_conversations_user_id ON "conversations"(user_id);
--> statement-breakpoint
CREATE INDEX idx_conversations_provider ON "conversations"(provider);
--> statement-breakpoint
CREATE INDEX idx_conversations_updated_at ON "conversations"(updated_at DESC);
--> statement-breakpoint
CREATE INDEX idx_conversations_prompt_template ON "conversations"(prompt_template_id);
--> statement-breakpoint

-- Indexes for chat_messages table
CREATE INDEX idx_chat_messages_conversation_id ON "chat_messages"(conversation_id);
--> statement-breakpoint
CREATE INDEX idx_chat_messages_created_at ON "chat_messages"(created_at);
--> statement-breakpoint

-- Indexes for conversation_ratings table
CREATE INDEX idx_conversation_ratings_conversation_id ON "conversation_ratings"(conversation_id);
--> statement-breakpoint
CREATE INDEX idx_conversation_ratings_rating ON "conversation_ratings"(rating);
--> statement-breakpoint

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE "prompt_templates" ENABLE ROW LEVEL SECURITY;
--> statement-breakpoint
ALTER TABLE "conversations" ENABLE ROW LEVEL SECURITY;
--> statement-breakpoint
ALTER TABLE "chat_messages" ENABLE ROW LEVEL SECURITY;
--> statement-breakpoint
ALTER TABLE "conversation_ratings" ENABLE ROW LEVEL SECURITY;
--> statement-breakpoint

-- Prompt Templates Policies
-- Users can read their own templates and public templates
CREATE POLICY "Users can read own and public templates"
  ON "prompt_templates" FOR SELECT
  USING (user_id = auth.uid() OR is_public = true);
--> statement-breakpoint

-- Users can insert their own templates
CREATE POLICY "Users can insert own templates"
  ON "prompt_templates" FOR INSERT
  WITH CHECK (user_id = auth.uid());
--> statement-breakpoint

-- Users can update their own templates
CREATE POLICY "Users can update own templates"
  ON "prompt_templates" FOR UPDATE
  USING (user_id = auth.uid());
--> statement-breakpoint

-- Users can delete their own templates
CREATE POLICY "Users can delete own templates"
  ON "prompt_templates" FOR DELETE
  USING (user_id = auth.uid());
--> statement-breakpoint

-- Conversations Policies
CREATE POLICY "Users can read own conversations"
  ON "conversations" FOR SELECT
  USING (user_id = auth.uid());
--> statement-breakpoint

CREATE POLICY "Users can insert own conversations"
  ON "conversations" FOR INSERT
  WITH CHECK (user_id = auth.uid());
--> statement-breakpoint

CREATE POLICY "Users can update own conversations"
  ON "conversations" FOR UPDATE
  USING (user_id = auth.uid());
--> statement-breakpoint

CREATE POLICY "Users can delete own conversations"
  ON "conversations" FOR DELETE
  USING (user_id = auth.uid());
--> statement-breakpoint

-- Chat Messages Policies
CREATE POLICY "Users can read messages from own conversations"
  ON "chat_messages" FOR SELECT
  USING (user_id = auth.uid());
--> statement-breakpoint

CREATE POLICY "Users can insert own messages"
  ON "chat_messages" FOR INSERT
  WITH CHECK (user_id = auth.uid());
--> statement-breakpoint

-- Conversation Ratings Policies
CREATE POLICY "Users can read own ratings"
  ON "conversation_ratings" FOR SELECT
  USING (user_id = auth.uid());
--> statement-breakpoint

CREATE POLICY "Users can insert own ratings"
  ON "conversation_ratings" FOR INSERT
  WITH CHECK (user_id = auth.uid());
--> statement-breakpoint

CREATE POLICY "Users can update own ratings"
  ON "conversation_ratings" FOR UPDATE
  USING (user_id = auth.uid());
--> statement-breakpoint

CREATE POLICY "Users can delete own ratings"
  ON "conversation_ratings" FOR DELETE
  USING (user_id = auth.uid());
--> statement-breakpoint

-- ============================================================================
-- TRIGGER FUNCTION FOR AUTO-UPDATING CONVERSATION METADATA
-- ============================================================================

-- Function to update conversation message count and updated_at timestamp
CREATE OR REPLACE FUNCTION update_conversation_metadata()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET
    message_count = message_count + 1,
    updated_at = NOW()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--> statement-breakpoint

-- Trigger to update conversation metadata when a message is inserted
CREATE TRIGGER on_message_insert
  AFTER INSERT ON "chat_messages"
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_metadata();