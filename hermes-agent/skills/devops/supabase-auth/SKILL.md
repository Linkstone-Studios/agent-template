# Supabase User-Authenticated Operations

This skill enables Hermes to perform Supabase operations on behalf of authenticated users, respecting Row Level Security (RLS) policies.

## Overview

When Hermes is called via the Supabase Edge Function proxy (`hermes-proxy`), the proxy validates the user's JWT and passes user context via custom headers:

- `X-User-ID`: The authenticated user's Supabase user ID
- `X-User-Email`: The user's email address
- `X-Supabase-Token`: The original JWT token for making Supabase API calls

## Environment Variables

Required in Hermes Agent `.env`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Optional (for admin operations):
```env
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Python Usage

### Reading User Context from Headers

```python
import os

def get_user_context():
    """Extract user context from request headers (set by Supabase proxy)"""
    return {
        'user_id': os.environ.get('X_USER_ID'),
        'user_email': os.environ.get('X_USER_EMAIL'),
        'token': os.environ.get('X_SUPABASE_TOKEN'),
    }
```

### Making Authenticated Supabase Calls

```python
from supabase import create_client, Client

# For user-scoped operations (respects RLS)
def get_user_supabase_client() -> Client:
    """Create Supabase client with user's JWT token"""
    url = os.environ.get('SUPABASE_URL')
    token = os.environ.get('X_SUPABASE_TOKEN')
    
    if not url or not token:
        raise ValueError('Missing Supabase credentials or user token')
    
    # Use the user's JWT token as the auth token
    client = create_client(url, token)
    return client

# For admin operations (bypasses RLS)
def get_admin_supabase_client() -> Client:
    """Create Supabase client with service role key (bypasses RLS)"""
    url = os.environ.get('SUPABASE_URL')
    key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if not url or not key:
        raise ValueError('Missing Supabase admin credentials')
    
    return create_client(url, key)
```

### Example: Query User's Conversations

```python
def get_user_conversations():
    """Fetch conversations for the authenticated user"""
    user_ctx = get_user_context()
    supabase = get_user_supabase_client()
    
    # This query will only return rows where user_id matches (due to RLS)
    result = supabase.table('conversations') \
        .select('*') \
        .eq('user_id', user_ctx['user_id']) \
        .order('created_at', desc=True) \
        .execute()
    
    return result.data

# Call with: terminal(command='python -c "from skills.supabase import *; print(get_user_conversations())"')
```

### Example: Create Chat Message

```python
def save_chat_message(conversation_id: str, role: str, content: str):
    """Save a chat message on behalf of the authenticated user"""
    user_ctx = get_user_context()
    supabase = get_user_supabase_client()
    
    result = supabase.table('chat_messages').insert({
        'conversation_id': conversation_id,
        'user_id': user_ctx['user_id'],
        'role': role,
        'content': content,
    }).execute()
    
    return result.data
```

## Authentication Flow

```
┌─────────────┐         ┌──────────────────┐         ┌──────────────┐
│ Flutter App │ ──JWT──>│ Supabase Edge    │ ──────> │ Hermes Agent │
│             │         │ Function Proxy   │         │              │
└─────────────┘         └──────────────────┘         └──────────────┘
                               │
                               ├─ Validates JWT
                               ├─ Checks subscription (optional)
                               ├─ Extracts user info
                               └─ Forwards with headers:
                                    X-User-ID
                                    X-User-Email
                                    X-Supabase-Token
```

## Security Notes

1. **Never expose service role key to client** - Only use in Hermes backend
2. **Use user token for RLS operations** - Ensures users only access their own data
3. **Validate user context** - Always check that user_id and token are present
4. **Headers are set by proxy** - Don't accept these headers directly from untrusted clients

## Installation

```bash
pip install supabase
```

## Best Practices

- **Default to user token**: Use `get_user_supabase_client()` for all operations unless admin access is required
- **Respect RLS**: Don't try to bypass RLS unless absolutely necessary
- **Log operations**: Track which user performed which operations for audit trails
- **Handle missing context gracefully**: Check if headers are present before making calls

