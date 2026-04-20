import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:agent_template/features/chat/providers/ai_provider_factory.dart';

part 'remote_config_service.g.dart';

/// Service for managing Firebase Remote Config
///
/// Provides runtime configuration for A/B testing, feature flags,
/// and dynamic app behavior without app updates.
///
/// Key features:
/// - Deterministic hash-based A/B testing
/// - Configurable provider percentage split
/// - Feature flags for tools and provider switching
/// - Sticky user assignments (same user always gets same provider)
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize Remote Config with defaults and fetch latest values
  Future<void> initialize() async {
    // Configure fetch settings
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 12),
      ),
    );

    // Set default values (used if fetch fails or before first fetch)
    await _remoteConfig.setDefaults({
      'ai_provider_default': 'hermes',
      'ai_provider_percentage': 100, // % of users on Hermes (100 = all Hermes, 0 = all Firebase)
      'enable_provider_switching': true,
      'enable_tools': true,
      'max_conversation_turns': 50,
    });

    // Fetch and activate remote values
    await _remoteConfig.fetchAndActivate();
  }

  /// Get assigned provider using deterministic hash-based A/B testing
  ///
  /// Uses user ID hash to consistently assign users to the same provider.
  /// This ensures the same user always gets the same experience across sessions.
  ///
  /// Algorithm:
  /// 1. Hash user ID to get a number
  /// 2. Take modulo 100 to get a percentage bucket (0-99)
  /// 3. If bucket < ai_provider_percentage, use Hermes
  /// 4. Otherwise, use Firebase AI
  ///
  /// Example: If ai_provider_percentage = 25, users with hash % 100 < 25
  ///          get Hermes (25%), the rest get Firebase AI (75%)
  AIProviderType getAssignedProvider(String userId) {
    final percentage = _remoteConfig.getInt('ai_provider_percentage');
    
    // Hash user ID to get consistent assignment
    final userHash = userId.hashCode.abs() % 100;

    if (userHash < percentage) {
      // User falls in Hermes bucket
      return AIProviderType.hermes;
    } else {
      // User falls in Firebase AI bucket
      return AIProviderType.firebaseAI;
    }
  }

  /// Get default provider (fallback if user ID not available)
  AIProviderType get defaultProvider {
    final defaultStr = _remoteConfig.getString('ai_provider_default');
    return AIProviderTypeExtension.fromString(defaultStr);
  }

  /// Whether users can manually switch providers
  bool get enableProviderSwitching =>
      _remoteConfig.getBool('enable_provider_switching');

  /// Whether tool/function calling is enabled globally
  bool get enableTools => _remoteConfig.getBool('enable_tools');

  /// Maximum number of turns allowed in a conversation
  int get maxConversationTurns =>
      _remoteConfig.getInt('max_conversation_turns');

  /// Get the current Hermes percentage (for analytics/logging)
  int get hermesPercentage => _remoteConfig.getInt('ai_provider_percentage');

  /// Force a refresh of remote config values
  /// 
  /// This respects the minimumFetchInterval setting. If called too frequently,
  /// it will return cached values without fetching.
  Future<bool> refresh() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Return false if fetch fails (will use cached/default values)
      return false;
    }
  }
}

/// Riverpod provider for RemoteConfigService
@Riverpod(keepAlive: true)
RemoteConfigService remoteConfigService(Ref ref) {
  return RemoteConfigService();
}

/// Provider for the assigned AI provider type based on Remote Config
///
/// This provider automatically assigns users to A/B test buckets based on
/// their user ID and Remote Config settings.
@riverpod
AIProviderType assignedAiProvider(Ref ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  
  // Get current user ID from Supabase
  // Note: This will be populated once auth is implemented
  // For now, use a default or environment variable
  final userId = 'default-user'; // TODO: Get from auth
  
  return remoteConfig.getAssignedProvider(userId);
}

