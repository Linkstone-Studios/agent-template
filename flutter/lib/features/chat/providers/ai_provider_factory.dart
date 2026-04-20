import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:agent_template/data/providers/supabase_provider.dart';
import 'package:agent_template/data/repositories/conversation_repository.dart';
import 'package:agent_template/core/services/remote_config_service.dart';
import 'package:agent_template/core/services/analytics_service.dart';
import 'package:agent_template/core/utils/logger.dart';
import 'ai_chat_provider.dart';
import 'hermes_provider.dart';
import 'firebase_ai_provider.dart';
import 'conversation_aware_provider.dart';

part 'ai_provider_factory.g.dart';

final _log = AppLogger.getLogger('AIProviderFactory');

/// Feature flag to determine which AI provider to use
enum AIProviderType {
  /// Hermes Agent on DigitalOcean with Google AI Studio
  hermes,

  /// Firebase AI with direct Google AI Studio integration (not yet implemented)
  firebaseAI,
}

/// Extension to convert string to AIProviderType
extension AIProviderTypeExtension on AIProviderType {
  String get name {
    switch (this) {
      case AIProviderType.hermes:
        return 'hermes';
      case AIProviderType.firebaseAI:
        return 'firebase_ai';
    }
  }

  static AIProviderType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'firebase_ai':
      case 'firebaseai':
        return AIProviderType.firebaseAI;
      case 'hermes':
      default:
        return AIProviderType.hermes;
    }
  }
}

/// Riverpod provider for the active AI provider type
///
/// This determines which provider to use based on:
/// 1. Firebase Remote Config A/B testing (if user is authenticated)
/// 2. Environment variable (compile-time via --dart-define)
/// 3. User preference (manual override)
///
/// Priority order:
/// - User manual override (if set)
/// - Remote Config A/B assignment (for authenticated users)
/// - Environment variable (fallback)
@riverpod
class AiProviderType extends _$AiProviderType {
  AIProviderType? _manualOverride;

  @override
  AIProviderType build() {
    // 1. Check for manual override
    if (_manualOverride != null) {
      return _manualOverride!;
    }

    // 2. Try to get from Remote Config for A/B testing
    try {
      final remoteConfig = ref.read(remoteConfigServiceProvider);
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;

      if (user != null) {
        // User is authenticated - use Remote Config A/B assignment
        final assigned = remoteConfig.getAssignedProvider(user.id);

        // Log the assignment to analytics
        final analytics = ref.read(analyticsServiceProvider);
        analytics.setUserProperties(
          assignedProvider: assigned.name,
          isPremium: false, // TODO: Get from subscription status
        );

        return assigned;
      }
    } catch (e) {
      // Remote Config not initialized or failed - fall through to default
      _log.warning('Failed to get Remote Config provider assignment: $e');
    }

    // 3. Fallback to environment variable or default
    const envProvider = String.fromEnvironment(
      'AI_PROVIDER',
      defaultValue: 'hermes',
    );

    return AIProviderTypeExtension.fromString(envProvider);
  }

  /// Manually override the provider type
  /// This bypasses Remote Config and environment variables
  void setProvider(AIProviderType type, {String reason = 'manual'}) {
    final previousProvider = state.name;
    _manualOverride = type;
    state = type;

    // Log the provider switch
    final analytics = ref.read(analyticsServiceProvider);
    analytics.logProviderSwitch(
      fromProvider: previousProvider,
      toProvider: type.name,
      reason: reason,
    );
  }

  /// Update from string value
  void setProviderFromString(String value, {String reason = 'manual'}) {
    setProvider(AIProviderTypeExtension.fromString(value), reason: reason);
  }

  /// Clear manual override and return to A/B assignment
  void clearOverride() {
    _manualOverride = null;
    // Force rebuild to get fresh assignment
    ref.invalidateSelf();
  }
}

/// Factory provider that creates the appropriate AI chat provider
/// based on the current provider type
///
/// This is the main provider that should be used throughout the app
/// for accessing AI chat functionality.
///
/// The provider is wrapped in ConversationAwareProvider to enable
/// automatic message persistence to the database.
///
/// Note: This provider is kept alive to prevent premature disposal
/// during provider switches or widget rebuilds.
@Riverpod(keepAlive: true)
AIChatProvider aiChatProvider(Ref ref) {
  final providerType = ref.watch(aiProviderTypeProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  final conversationRepo = ref.watch(conversationRepositoryProvider);

  _log.info('Creating AI provider for type: ${providerType.name}');

  // Create base provider based on type
  final baseProvider = switch (providerType) {
    AIProviderType.hermes => HermesProvider(
      supabase: supabase,
      model: 'gemini-3-flash-preview',
      analyticsService: analytics,
    ),
    AIProviderType.firebaseAI => FirebaseAIProvider(
      supabase: supabase,
      model: 'gemini-3-flash-preview', // Changed from gemini-2.0-flash-exp
      analyticsService: analytics,
    ),
  };

  // Wrap in ConversationAwareProvider for auto-save functionality
  final provider = ConversationAwareProvider(
    wrappedProvider: baseProvider,
    repository: conversationRepo,
  );

  _log.info('Created ${provider.providerName} (${provider.providerId})');

  return provider;
}

/// Provider that exposes the current provider's metadata
/// for analytics and debugging
@riverpod
Map<String, dynamic> currentProviderMetadata(Ref ref) {
  final provider = ref.watch(aiChatProviderProvider);
  return {
    'provider_id': provider.providerId,
    'provider_name': provider.providerName,
    'model': provider.model,
    'capabilities': {
      'streaming': provider.capabilities.supportsStreaming,
      'tools': provider.capabilities.supportsTools,
      'multimodal': provider.capabilities.supportsMultimodal,
      'vision': provider.capabilities.supportsVision,
      'audio': provider.capabilities.supportsAudio,
      'max_tokens': provider.capabilities.maxTokens,
    },
    ...provider.metadata,
  };
}

/// Provider that exposes the current provider's capabilities
@riverpod
ProviderCapabilities currentProviderCapabilities(Ref ref) {
  final provider = ref.watch(aiChatProviderProvider);
  return provider.capabilities;
}

/// Provider for checking if the current provider supports a specific capability
@riverpod
bool providerSupportsFeature(Ref ref, ProviderFeature feature) {
  final capabilities = ref.watch(currentProviderCapabilitiesProvider);

  switch (feature) {
    case ProviderFeature.streaming:
      return capabilities.supportsStreaming;
    case ProviderFeature.tools:
      return capabilities.supportsTools;
    case ProviderFeature.multimodal:
      return capabilities.supportsMultimodal;
    case ProviderFeature.vision:
      return capabilities.supportsVision;
    case ProviderFeature.audio:
      return capabilities.supportsAudio;
  }
}

/// Enum for provider features to check
enum ProviderFeature { streaming, tools, multimodal, vision, audio }
