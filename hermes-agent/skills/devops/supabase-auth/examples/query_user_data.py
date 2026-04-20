#!/usr/bin/env python3
"""
Example: Query user-specific data from Supabase

This script demonstrates how Hermes tools can access user data
when called via the Supabase Edge Function proxy.

Prerequisites:
- Hermes called via hermes-proxy Edge Function
- User context headers set by proxy
- SUPABASE_URL and SUPABASE_ANON_KEY in environment

Usage from Hermes skill:
    terminal(command="python skills/devops/supabase-auth/examples/query_user_data.py")
"""

import os
import sys
from supabase import create_client, Client


def get_user_context():
    """Extract user context from headers set by hermes-proxy"""
    user_id = os.environ.get('X_USER_ID')
    user_email = os.environ.get('X_USER_EMAIL')
    token = os.environ.get('X_SUPABASE_TOKEN')
    
    if not user_id or not token:
        raise ValueError(
            "User context not found. This script must be called via hermes-proxy. "
            "Headers X_USER_ID and X_SUPABASE_TOKEN are required."
        )
    
    return {
        'user_id': user_id,
        'user_email': user_email,
        'token': token,
    }


def get_user_supabase_client() -> Client:
    """Create Supabase client with user's JWT (respects RLS)"""
    url = os.environ.get('SUPABASE_URL')
    user_ctx = get_user_context()
    
    if not url:
        raise ValueError("SUPABASE_URL environment variable not set")
    
    # Use user's JWT token instead of anon key
    # This ensures all queries respect Row Level Security
    return create_client(url, user_ctx['token'])


def get_user_conversations():
    """Fetch all conversations for the authenticated user"""
    user_ctx = get_user_context()
    supabase = get_user_supabase_client()
    
    result = supabase.table('conversations') \
        .select('*') \
        .eq('user_id', user_ctx['user_id']) \
        .order('created_at', desc=True) \
        .execute()
    
    return result.data


def get_conversation_messages(conversation_id: str):
    """Fetch all messages in a conversation"""
    user_ctx = get_user_context()
    supabase = get_user_supabase_client()
    
    # First verify the conversation belongs to the user
    conversation = supabase.table('conversations') \
        .select('*') \
        .eq('id', conversation_id) \
        .eq('user_id', user_ctx['user_id']) \
        .single() \
        .execute()
    
    if not conversation.data:
        raise ValueError(f"Conversation {conversation_id} not found or access denied")
    
    # Fetch messages
    messages = supabase.table('chat_messages') \
        .select('*') \
        .eq('conversation_id', conversation_id) \
        .order('created_at', asc=True) \
        .execute()
    
    return messages.data


def get_user_usage_stats():
    """Get AI usage statistics for the user"""
    user_ctx = get_user_context()
    supabase = get_user_supabase_client()
    
    # Get total usage
    usage = supabase.table('ai_usage_logs') \
        .select('provider, model, input_tokens, output_tokens, cost_usd') \
        .eq('user_id', user_ctx['user_id']) \
        .execute()
    
    if not usage.data:
        return {"total_requests": 0, "total_cost": 0, "by_provider": {}}
    
    # Aggregate stats
    total_cost = sum(float(log.get('cost_usd', 0) or 0) for log in usage.data)
    total_tokens = sum(
        (log.get('input_tokens', 0) or 0) + (log.get('output_tokens', 0) or 0)
        for log in usage.data
    )
    
    # Group by provider
    by_provider = {}
    for log in usage.data:
        provider = log.get('provider', 'unknown')
        if provider not in by_provider:
            by_provider[provider] = {'count': 0, 'cost': 0}
        by_provider[provider]['count'] += 1
        by_provider[provider]['cost'] += float(log.get('cost_usd', 0) or 0)
    
    return {
        'total_requests': len(usage.data),
        'total_tokens': total_tokens,
        'total_cost_usd': round(total_cost, 4),
        'by_provider': by_provider,
    }


def main():
    """Main entry point"""
    try:
        user_ctx = get_user_context()
        print(f"✓ Authenticated as: {user_ctx['user_email']} ({user_ctx['user_id']})")
        print()
        
        # Get conversations
        print("📋 Your conversations:")
        conversations = get_user_conversations()
        for conv in conversations[:5]:  # Show first 5
            print(f"  - {conv['title']} ({conv['provider']}/{conv['model']})")
        print()
        
        # Get usage stats
        print("📊 Your usage statistics:")
        stats = get_user_usage_stats()
        print(f"  Total requests: {stats['total_requests']}")
        print(f"  Total tokens: {stats['total_tokens']:,}")
        print(f"  Total cost: ${stats['total_cost_usd']}")
        print(f"  By provider:")
        for provider, data in stats['by_provider'].items():
            print(f"    {provider}: {data['count']} requests, ${data['cost']:.4f}")
        
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()

