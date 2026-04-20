# Hermes AI Chat - Quick Start Guide

Welcome! This guide will help you test the new Hermes AI chat functionality.

## 🚀 Quick Start (30 seconds)

### 1. Enable Testing Mode

Skip subscription validation for testing:

```bash
# From project root
supabase secrets set SKIP_SUBSCRIPTION_CHECK=true
supabase functions deploy hermes-proxy
```

### 2. Run the App

```bash
cd flutter
flutter run
```

### 3. Test the Chat

1. Sign in with your credentials
2. Click "Chat with Hermes AI" button
3. Start chatting!

## 📋 What Was Added

### New Files

```
flutter/lib/features/chat/
├── providers/
│   └── hermes_provider.dart       # Custom LLM provider for Hermes
├── screens/
│   └── chat_screen.dart           # Chat UI using Flutter AI Toolkit
└── services/
    └── hermes_service.dart        # API communication layer
```

### Modified Files

- `flutter/pubspec.yaml` - Added `flutter_ai_toolkit` and `http` packages
- `flutter/lib/core/constants/api_constants.dart` - Added Hermes proxy URL
- `flutter/lib/main.dart` - Added navigation to chat screen
- `supabase/functions/hermes-proxy/index.ts` - Made subscription check optional

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│   Flutter App (Material UI)         │
│                                      │
│  ┌────────────────────────────┐    │
│  │  LlmChatView (AI Toolkit)   │    │
│  │  - Chat interface           │    │
│  │  - Streaming responses      │    │
│  │  - Message history          │    │
│  └────────────────────────────┘    │
│              ↓                       │
│  ┌────────────────────────────┐    │
│  │  HermesProvider             │    │
│  │  - Custom LLM provider      │    │
│  │  - Converts to OpenAI format│    │
│  └────────────────────────────┘    │
└─────────────────────────────────────┘
              ↓ (HTTPS + Auth)
┌─────────────────────────────────────┐
│  Supabase Edge Function             │
│  (hermes-proxy)                     │
│  - Validates authentication         │
│  - Checks subscription (optional)   │
│  - Forwards to Hermes               │
└─────────────────────────────────────┘
              ↓ (HTTP)
┌─────────────────────────────────────┐
│  Hermes Agent (DigitalOcean)        │
│  - AI processing                    │
│  - OpenAI-compatible API            │
│  - Port 8642                        │
└─────────────────────────────────────┘
```

## 🎨 Features

✅ **Implemented:**
- Text-based chat with Hermes
- Streaming responses (word-by-word)
- Multi-turn conversations with context
- Welcome message and suggested prompts
- Authentication through Supabase
- Clean Material Design UI

⏳ **Coming Soon:**
- Voice input (microphone permissions needed)
- Image/file attachments
- Chat history persistence
- Token usage tracking

## 🐛 Troubleshooting

### Issue: "User not authenticated"

**Solution:** Log out and log back in to refresh your session.

### Issue: "No active subscription found"

**Solution:** Enable testing mode:
```bash
supabase secrets set SKIP_SUBSCRIPTION_CHECK=true
supabase functions deploy hermes-proxy
```

### Issue: Chat screen is blank

**Solution:** Check if Hermes agent is running:
```bash
ssh root@YOUR_DROPLET_IP
cd /app/your-project/hermes-agent
docker-compose ps
docker-compose logs -f
```

### Issue: Build errors

**Solution:** Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

## 🔧 Configuration

### Change AI Model

Edit `lib/features/chat/screens/chat_screen.dart`:

```dart
HermesProvider(
  supabase: supabase,
  model: 'gemini-2.5-flash', // Change model here
)
```

### Customize Messages

Edit `lib/features/chat/screens/chat_screen.dart`:

```dart
welcomeMessage: 'Your custom greeting!',
messageSuggestions: const [
  'Custom suggestion 1',
  'Custom suggestion 2',
],
```

## 📚 Learn More

- [Flutter AI Toolkit Docs](https://docs.flutter.dev/ai/ai-toolkit)
- [Detailed Setup Guide](../docs/HERMES_CHAT_SETUP.md)
- [Hermes Integration](../docs/HERMES_INTEGRATION.md)

## 🎯 Next Steps

1. **Test the chat** - Send various messages and verify responses
2. **Check streaming** - Notice how responses appear word-by-word
3. **Test multi-turn** - Have a back-and-forth conversation
4. **Monitor logs** - Check for any errors in the console

Enjoy chatting with Hermes! 🚀

