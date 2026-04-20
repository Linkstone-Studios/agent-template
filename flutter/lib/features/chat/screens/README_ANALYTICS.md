# Analytics Dashboard

## Overview

The Analytics Dashboard provides insights into AI provider performance and prompt template effectiveness for AI tasks. This tool is designed for internal testing and optimization.

## Features

### 1. Key Metrics Cards
- **Best Provider**: Shows which AI provider (Hermes vs Firebase AI) has the highest average rating
- **Satisfaction Rate**: Percentage of conversations rated 4-5 stars
- **Top Template**: Most effective prompt template based on ratings

### 2. Provider Performance
- Compare Hermes Agent vs Firebase AI side-by-side
- View average ratings and total rated conversations
- Identify which provider works best for your use case

### 3. Template Effectiveness
- See which prompt templates produce the highest quality results
- Top 5 templates ranked by average rating
- Helps identify templates worth investing in vs. deprecating

### 4. Template Usage
- Most frequently used prompt templates
- Understand which templates teams prefer
- Identify popular templates for standardization

## Setup Instructions

### Step 1: Create Analytics Views (One-Time Setup)

1. Open Supabase Dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy the contents of `supabase/scripts/create_analytics_views.sql`
5. Paste into SQL Editor
6. Click **Run**

This creates 6 database views:
- `conversation_avg_rating_by_provider`
- `conversation_avg_rating_by_template`
- `prompt_template_usage_stats`
- `conversation_count_by_provider_over_time`
- `provider_template_performance_matrix`
- `user_conversation_engagement`

### Step 2: Access the Dashboard

**Option A: Navigate Manually**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AnalyticsDashboardScreen(),
  ),
);
```

**Option B: Add to Navigation** (Recommended)

Add analytics to your main navigation in `app_router.dart` or navigation wrapper.

## Usage

### Viewing Analytics

1. Launch the app and navigate to the Analytics Dashboard
2. Wait for data to load (shows loading indicators)
3. Scroll through sections:
   - Key Metrics (top summary cards)
   - Provider Performance (comparison list)
   - Template Effectiveness (top-rated templates)
   - Template Usage (most used templates)

### Refreshing Data

Pull down on the screen to refresh all analytics data.

### Understanding the Metrics

**Average Rating**: Mean of all 1-5 star ratings (higher is better)

**Satisfaction Percentage**: % of conversations rated 4-5 stars (target: 80%+)

**Rated Conversations**: Number of conversations with ratings (more data = more reliable)

**High/Low Ratings**: Count of 4-5 star vs 1-2 star ratings

## Data Requirements

Analytics require:
- At least 1 conversation with a rating
- Data from last 30 days (configurable in providers)

**Empty States:**
- If no data available, cards show "N/A" or "No data available yet"
- Create conversations and rate them to populate analytics

## Use Cases

### 1. A/B Testing Prompts
1. Create two prompt templates (e.g., "Question Gen v1" and "Question Gen v2")
2. Use both in conversations
3. Rate conversations based on quality
4. Check "Template Effectiveness" to see which performs better

### 2. Comparing Providers
1. Create conversations with Hermes Agent
2. Create similar conversations with Firebase AI
3. Rate both based on quality
4. Check "Provider Performance" to see which AI works best

### 3. Identifying Best Practices
1. Review "Top Template" in Key Metrics
2. Examine high-rated templates in "Template Effectiveness"
3. Standardize on proven prompts
4. Share effective templates with team (set `is_public = true`)

### 4. Performance Tracking
1. Monitor satisfaction rate over time
2. Identify trends (improving vs declining)
3. Investigate low-rated conversations to find issues
4. Iterate on prompts and provider selection

## Troubleshooting

### "No data available yet"
- **Cause**: No conversations have been rated
- **Solution**: 
  1. Create conversations via Chat screen
  2. Rate conversations using the star icon in chat
  3. Refresh analytics dashboard

### "Error loading data"
- **Cause**: Analytics views not created, or database permissions issue
- **Solution**:
  1. Verify you ran `create_analytics_views.sql`
  2. Check Supabase logs for errors
  3. Ensure RLS policies allow access to underlying tables

### Slow loading
- **Cause**: Large dataset (1000+ conversations)
- **Solutions**:
  1. Reduce date range in providers (edit `limitDays` parameter)
  2. Add database indexes (see optimization docs)
  3. Consider caching strategies

## Technical Details

### Architecture

```
AnalyticsDashboardScreen
  ├── Key Metrics Section
  │   ├── Best Provider (computed provider)
  │   ├── Satisfaction Rate (computed provider)
  │   └── Top Template (computed provider)
  ├── Provider Performance Section
  │   └── providerRatingStatsProvider (data provider)
  ├── Template Effectiveness Section
  │   └── templateRatingStatsProvider (data provider)
  └── Template Usage Section
      └── templateUsageStatsProvider (data provider)
```

### Data Flow

1. **UI Layer**: `AnalyticsDashboardScreen` (Flutter widget)
2. **Provider Layer**: `analytics_providers.dart` (Riverpod providers)
3. **Repository Layer**: `conversation_analytics_repository.dart` (data access)
4. **Database Layer**: Analytics views (SQL queries on conversation tables)

### Key Files

- `/flutter/lib/features/chat/screens/analytics_dashboard_screen.dart` - Main UI
- `/flutter/lib/features/chat/providers/analytics_providers.dart` - Data providers
- `/flutter/lib/data/repositories/conversation_analytics_repository.dart` - Data access
- `/supabase/scripts/create_analytics_views.sql` - Database setup

## Future Enhancements

See `docs/CONVERSATION_MANAGEMENT.md` "Optimization Opportunities (Phase 6)" for:
- Chart visualizations (fl_chart integration)
- Data export (CSV/JSON)
- Date range selectors
- Real-time updates
- Template comparison view

