CREATE TABLE "tool_executions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"session_id" uuid,
	"tool_name" text NOT NULL,
	"category" text NOT NULL,
	"args_hash" text NOT NULL,
	"execution_time_ms" integer NOT NULL,
	"success" boolean NOT NULL,
	"error_message" text,
	"cached" boolean DEFAULT false NOT NULL,
	"provider" "ai_provider" NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "tool_executions" ADD CONSTRAINT "tool_executions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tool_executions" ADD CONSTRAINT "tool_executions_session_id_user_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."user_sessions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint

-- Performance indexes for tool_executions
CREATE INDEX IF NOT EXISTS "idx_tool_executions_user_id" ON "tool_executions"("user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tool_executions_tool_name" ON "tool_executions"("tool_name");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tool_executions_created_at" ON "tool_executions"("created_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tool_executions_user_tool" ON "tool_executions"("user_id", "tool_name");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tool_executions_provider" ON "tool_executions"("provider");--> statement-breakpoint

-- Enable RLS
ALTER TABLE "tool_executions" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint

-- RLS Policy: Users can only see their own tool executions
CREATE POLICY "Users can view own tool executions" ON "tool_executions"
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);--> statement-breakpoint

-- RLS Policy: Users can insert their own tool executions
CREATE POLICY "Users can insert own tool executions" ON "tool_executions"
  AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);