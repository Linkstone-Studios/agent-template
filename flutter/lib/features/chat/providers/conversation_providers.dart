import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';

part 'conversation_providers.g.dart';

// ============================================================================
// State Providers
// ============================================================================

/// Current active conversation (null if creating new)
///
/// This provider tracks the current conversation being displayed in the chat
/// screen. Set this when:
/// - Creating a new conversation
/// - Resuming an existing conversation from the conversation list
/// - Switching between conversations
@riverpod
class CurrentConversation extends _$CurrentConversation {
  @override
  Conversations? build() => null;

  void set(Conversations? conversation) {
    state = conversation;
  }

  void clear() {
    state = null;
  }
}

/// Selected prompt template for new conversation
///
/// This provider tracks which prompt template should be used when creating
/// a new conversation. Set this in the "New Conversation" dialog before
/// navigating to the chat screen.
@riverpod
class SelectedPromptTemplate extends _$SelectedPromptTemplate {
  @override
  PromptTemplates? build() => null;

  void select(PromptTemplates? template) {
    state = template;
  }

  void clear() {
    state = null;
  }
}

// ============================================================================
// Data Providers
// ============================================================================

/// Fetch all conversations for current user
///
/// Returns conversations sorted by most recently updated first.
/// By default, excludes archived conversations.
@riverpod
Future<List<Conversations>> conversationList(
  Ref ref, {
  bool includeArchived = false,
}) async {
  final repository = ref.watch(conversationRepositoryProvider);
  return repository.getConversations(includeArchived: includeArchived);
}

/// Fetch all prompt templates (user's + public)
///
/// Returns templates the current user created plus any templates
/// marked as public for sharing across the team.
@riverpod
Future<List<PromptTemplates>> promptTemplates(Ref ref) async {
  final repository = ref.watch(promptTemplateRepositoryProvider);
  return repository.getTemplates();
}

/// Fetch default prompt template for current user
///
/// Returns the template marked as default, or null if no default is set.
/// Users can have at most one default template.
@riverpod
Future<PromptTemplates?> defaultPromptTemplate(Ref ref) async {
  final repository = ref.watch(promptTemplateRepositoryProvider);
  return repository.getDefaultTemplate();
}

/// Fetch a specific conversation with all its messages
///
/// Used when resuming a conversation to restore full context.
/// Returns both the conversation metadata and all messages in chronological order.
@riverpod
Future<ConversationWithMessages> conversationWithMessages(
  Ref ref,
  String conversationId,
) async {
  final repository = ref.watch(conversationRepositoryProvider);
  return repository.getConversationWithMessages(conversationId);
}

/// Fetch rating for a specific conversation
///
/// Returns the current user's rating for the conversation, or null if
/// they haven't rated it yet.
@riverpod
Future<ConversationRatings?> conversationRating(
  Ref ref,
  String conversationId,
) async {
  final repository = ref.watch(conversationRepositoryProvider);
  return repository.getRating(conversationId);
}

