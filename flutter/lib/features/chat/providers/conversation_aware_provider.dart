import 'package:logging/logging.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../models/chat_message.dart';
import 'ai_chat_provider.dart';

final _log = Logger('ConversationAwareProvider');

/// Decorator that wraps an AIChatProvider to auto-save messages to the database
///
/// This provider intercepts message lifecycle events and persists them to Supabase,
/// enabling conversation history, resume functionality, and audit trails.
///
/// Architecture: Decorator Pattern
/// - Wraps any AIChatProvider implementation
/// - Delegates all operations to wrapped provider
/// - Intercepts sendMessageStream to save messages
/// - Handles errors gracefully (won't break chat if DB fails)
class ConversationAwareProvider extends AIChatProvider {
  final AIChatProvider _wrappedProvider;
  final ConversationRepository _repository;

  ConversationAwareProvider({
    required AIChatProvider wrappedProvider,
    required ConversationRepository repository,
  }) : _wrappedProvider = wrappedProvider,
       _repository = repository {
    // Forward change notifications from wrapped provider
    _wrappedProvider.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _wrappedProvider.removeListener(notifyListeners);
    _wrappedProvider.dispose();
    super.dispose();
  }

  // ========================================================================
  // Message Interception with Auto-Save
  // ========================================================================

  @override
  Stream<String> sendMessageStream(String prompt) async* {
    // Save user message BEFORE forwarding to provider
    await _saveUserMessage(prompt);

    // Forward to wrapped provider and accumulate response
    final buffer = StringBuffer();

    try {
      await for (final chunk in _wrappedProvider.sendMessageStream(prompt)) {
        buffer.write(chunk);
        yield chunk;
      }

      // Save complete assistant message AFTER streaming completes
      await _saveAssistantMessage(buffer.toString());
    } catch (e) {
      _log.severe('Error in message stream: $e');

      // Still try to save partial response if we got any
      if (buffer.isNotEmpty) {
        await _saveAssistantMessage(buffer.toString());
      }

      rethrow; // Propagate error to UI
    }
  }

  /// Save user message to database
  Future<void> _saveUserMessage(String content) async {
    final conversationId = _wrappedProvider.conversationId;

    if (conversationId == null) {
      _log.warning('Cannot save message: conversationId is null');
      return;
    }

    try {
      await _repository.saveMessage(
        conversationId: conversationId,
        role: MessageRole.user,
        content: content,
      );
      _log.fine('Saved user message to conversation $conversationId');
    } catch (e) {
      // Log error but don't throw - we don't want to break the chat
      _log.severe('Failed to save user message: $e');
    }
  }

  /// Save assistant message to database
  Future<void> _saveAssistantMessage(String content) async {
    final conversationId = _wrappedProvider.conversationId;

    if (conversationId == null) {
      _log.warning('Cannot save message: conversationId is null');
      return;
    }

    // Don't save empty messages - prevents empty bubbles on conversation resume
    if (content.trim().isEmpty) {
      _log.warning('Skipping save of empty assistant message');
      return;
    }

    try {
      await _repository.saveMessage(
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: content,
      );
      _log.fine('Saved assistant message to conversation $conversationId');
    } catch (e) {
      // Log error but don't throw
      _log.severe('Failed to save assistant message: $e');
    }
  }

  // ========================================================================
  // Delegate All Other Methods to Wrapped Provider
  // ========================================================================

  @override
  List<ChatMessage> get history => _wrappedProvider.history;

  @override
  set history(List<ChatMessage> value) => _wrappedProvider.history = value;

  // ========================================================================
  // AIChatProvider Interface Delegation
  // ========================================================================

  @override
  String get providerId => _wrappedProvider.providerId;

  @override
  String get providerName => _wrappedProvider.providerName;

  @override
  ProviderCapabilities get capabilities => _wrappedProvider.capabilities;

  @override
  String? get model => _wrappedProvider.model;

  @override
  String? get systemPrompt => _wrappedProvider.systemPrompt;

  @override
  void updateSystemPrompt(String? prompt) {
    _wrappedProvider.updateSystemPrompt(prompt);
  }

  @override
  String? get conversationId => _wrappedProvider.conversationId;

  @override
  void setConversationId(String? id) {
    _wrappedProvider.setConversationId(id);
  }

  @override
  Future<ToolResult> executeTool(String toolName, Map<String, dynamic> args) =>
      _wrappedProvider.executeTool(toolName, args);

  @override
  List<ToolDefinition> get availableTools => _wrappedProvider.availableTools;

  @override
  Map<String, dynamic> get metadata => {
    ..._wrappedProvider.metadata,
    'wrapped': true,
    'wrapper': 'ConversationAwareProvider',
  };
}
