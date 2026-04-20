import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/supabase_provider.dart';

part 'conversation_repository.g.dart';

/// Repository for managing conversations, messages, and ratings
/// Provides type-safe access to conversation management tables
@riverpod
ConversationRepository conversationRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return ConversationRepository(client);
}

/// Wrapper class for conversation with messages
/// Note: This is NOT a generated model. It's a repository-layer class
/// for convenience when loading a conversation with its full message history.
class ConversationWithMessages {
  final Conversations conversation;
  final List<ChatMessages> messages;

  ConversationWithMessages({
    required this.conversation,
    required this.messages,
  });
}

class ConversationRepository {
  final SupabaseClient _client;

  ConversationRepository(this._client);

  /// Create a new conversation
  ///
  /// Used when starting a new chat session. Links to a prompt template
  /// if testing a specific prompt configuration.
  Future<Conversations> createConversation({
    required AiProvider provider,
    required String model,
    String? title,
    String? promptTemplateId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('conversations')
        .insert({
          'user_id': userId,
          'provider': provider.value,
          'model': model,
          'title': title ?? 'New Conversation',
          'prompt_template_id': promptTemplateId,
        })
        .select()
        .single();

    return Conversations.fromJson(response);
  }

  /// Get all conversations for current user
  Future<List<Conversations>> getConversations({
    bool includeArchived = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Build query - only filter by is_archived if we don't want archived conversations
    final query = _client.from('conversations').select().eq('user_id', userId);

    final response = includeArchived
        ? await query.order('updated_at', ascending: false)
        : await query
              .eq('is_archived', false)
              .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Conversations.fromJson(json))
        .toList();
  }

  /// Get a specific conversation with all its messages
  ///
  /// Used when resuming a conversation to restore full context.
  Future<ConversationWithMessages> getConversationWithMessages(
    String conversationId,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get conversation
    final convResponse = await _client
        .from('conversations')
        .select()
        .eq('id', conversationId)
        .eq('user_id', userId)
        .single();

    final conversation = Conversations.fromJson(convResponse);

    // Get messages
    final messagesResponse = await _client
        .from('chat_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    final messages = (messagesResponse as List)
        .map((json) => ChatMessages.fromJson(json as Map<String, dynamic>))
        .toList();

    return ConversationWithMessages(
      conversation: conversation,
      messages: messages,
    );
  }

  /// Update conversation title
  Future<void> updateTitle(String conversationId, String title) async {
    await _client
        .from('conversations')
        .update({'title': title})
        .eq('id', conversationId);
  }

  /// Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    await _client
        .from('conversations')
        .update({'is_archived': true})
        .eq('id', conversationId);
  }

  /// Unarchive conversation
  Future<void> unarchiveConversation(String conversationId) async {
    await _client
        .from('conversations')
        .update({'is_archived': false})
        .eq('id', conversationId);
  }

  /// Delete conversation (and all messages via cascade)
  Future<void> deleteConversation(String conversationId) async {
    await _client.from('conversations').delete().eq('id', conversationId);
  }

  /// Save a message to a conversation
  ///
  /// The database trigger will automatically update the conversation's
  /// message count and updated_at timestamp.
  Future<ChatMessages> saveMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('chat_messages')
        .insert({
          'conversation_id': conversationId,
          'user_id': userId,
          'role': role.value,
          'content': content,
          'metadata': metadata != null ? metadata.toString() : '{}',
        })
        .select()
        .single();

    return ChatMessages.fromJson(response);
  }

  /// Rate a conversation
  ///
  /// Uses upsert to allow updating existing ratings. One rating per user per conversation.
  Future<ConversationRatings> rateConversation({
    required String conversationId,
    required int rating,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    final response = await _client
        .from('conversation_ratings')
        .upsert({
          'conversation_id': conversationId,
          'user_id': userId,
          'rating': rating,
          'notes': notes,
        })
        .select()
        .single();

    return ConversationRatings.fromJson(response);
  }

  /// Get rating for a conversation
  Future<ConversationRatings?> getRating(String conversationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('conversation_ratings')
        .select()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ConversationRatings.fromJson(response);
  }
}
