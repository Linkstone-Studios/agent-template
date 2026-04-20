CREATE TYPE "public"."deployment_type" AS ENUM('web', 'ios', 'android');--> statement-breakpoint
CREATE TYPE "public"."platform" AS ENUM('web', 'ios', 'android');--> statement-breakpoint
CREATE TABLE "app_versions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"version" text NOT NULL,
	"provider" "ai_provider" NOT NULL,
	"feature_suffix" text,
	"build_number" integer NOT NULL,
	"deployed_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deployment_type" "deployment_type" NOT NULL,
	"git_commit_hash" text,
	"active" boolean DEFAULT true
);
--> statement-breakpoint
CREATE TABLE "user_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"app_version" text NOT NULL,
	"provider" "ai_provider" NOT NULL,
	"platform" "platform" NOT NULL,
	"session_start" timestamp with time zone DEFAULT now() NOT NULL,
	"session_end" timestamp with time zone,
	"messages_sent" integer DEFAULT 0,
	"errors_count" integer DEFAULT 0
);
--> statement-breakpoint
ALTER TABLE "user_sessions" ADD CONSTRAINT "user_sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint
-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS "idx_app_versions_provider" ON "app_versions"("provider");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_app_versions_deployed_at" ON "app_versions"("deployed_at" DESC);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_user_sessions_user_id" ON "user_sessions"("user_id");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_user_sessions_app_version" ON "user_sessions"("app_version");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_user_sessions_provider" ON "user_sessions"("provider");