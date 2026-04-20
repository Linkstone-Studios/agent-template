import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../../../data/repositories/prompt_template_repository.dart';
import '../models/chat_message.dart';
import '../providers/ai_provider_factory.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/conversation_providers.dart';
import '../widgets/capability_badges.dart';
import '../widgets/conversation_info_dialog.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/custom_chat_view.dart';

final _log = Logger('ChatScreen');

/// Chat screen that uses Flutter AI Toolkit with an agnostic AI provider
///
/// Integrates conversation management for:
/// - Creating/resuming conversations
/// - Rating conversations
/// - Viewing conversation metadata
/// - (Phase 5: Auto-saving messages to database)
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _isInitialized = false;
  String? _conversationId;

  // Lazy conversation creation - store config until first message
  bool _pendingConversation = false;
  AIProviderType? _pendingProviderType;
  String? _pendingModel;
  String? _pendingTemplateId;

  // Lazy conversation provider - created once and reused
  _LazyConversationProvider? _lazyProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _initializeConversation();
    }
  }

  @override
  void dispose() {
    // Dispose lazy provider if it exists
    _lazyProvider?.dispose();
    super.dispose();
  }

  /// Initialize or resume a conversation
  Future<void> _initializeConversation() async {
    final repository = ref.read(conversationRepositoryProvider);
    final currentConversation = ref.read(currentConversationProvider);
    final selectedTemplate = ref.read(selectedPromptTemplateProvider);
    final providerType = ref.read(aiProviderTypeProvider);
    final aiProvider = ref.read(aiChatProviderProvider);

    try {
      if (currentConversation != null) {
        // Resuming existing conversation
        _conversationId = currentConversation.id;

        // Set conversation ID on provider for message auto-save
        aiProvider.setConversationId(currentConversation.id);

        // Load conversation with all its messages
        final conversationWithMessages = await repository
            .getConversationWithMessages(currentConversation.id);

        // Convert database messages to ChatMessage objects and restore history
        // Filter out empty messages to prevent empty bubbles
        final chatMessages = conversationWithMessages.messages
            .where((dbMsg) => dbMsg.content.trim().isNotEmpty)
            .map((dbMsg) {
              if (dbMsg.role == MessageRole.user) {
                return ChatMessage(
                  id: dbMsg.id,
                  origin: MessageOrigin.user,
                  text: dbMsg.content,
                  timestamp: dbMsg.createdAt,
                  status: MessageStatus.sent,
                );
              } else {
                // assistant or system messages
                return ChatMessage(
                  id: dbMsg.id,
                  origin: MessageOrigin.assistant,
                  text: dbMsg.content,
                  timestamp: dbMsg.createdAt,
                  status: MessageStatus.sent,
                );
              }
            })
            .toList();

        // Restore the conversation history in the AI provider
        aiProvider.history = chatMessages;
        _log.info(
          'Restored ${chatMessages.length} messages for conversation ${currentConversation.id}',
        );

        // Load and apply prompt template if conversation has one
        if (currentConversation.promptTemplateId != null) {
          final templateRepo = ref.read(promptTemplateRepositoryProvider);
          try {
            final templates = await templateRepo.getTemplates();
            final template = templates.firstWhere(
              (t) => t.id == currentConversation.promptTemplateId,
            );
            aiProvider.updateSystemPrompt(template.systemPrompt);
          } catch (e) {
            // Template not found or error loading - continue without it
          }
        }
      } else {
        // LAZY CREATION: Store config but don't create conversation yet
        // Conversation will be created when first message is sent
        _pendingConversation = true;
        _pendingProviderType = providerType;
        _pendingModel = _getModelName(providerType);
        _pendingTemplateId = selectedTemplate?.id;

        // Clear any existing history for new conversation
        aiProvider.history = [];
        _log.info('Starting new conversation - cleared provider history');

        // Update provider with system prompt from template
        if (selectedTemplate != null) {
          aiProvider.updateSystemPrompt(selectedTemplate.systemPrompt);
        }
      }
    } catch (e) {
      // Show error snackbar if conversation creation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize conversation: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  AiProvider _getAiProvider(AIProviderType type) {
    switch (type) {
      case AIProviderType.hermes:
        return AiProvider.hermes;
      case AIProviderType.firebaseAI:
        return AiProvider.firebaseAi;
    }
  }

  String _getModelName(AIProviderType type) {
    switch (type) {
      case AIProviderType.hermes:
        return 'gemini-3-flash-preview';
      case AIProviderType.firebaseAI:
        return 'gemini-3-flash-preview'; // Changed to match Hermes
    }
  }

  String _getProviderDisplayName(AIProviderType type) {
    switch (type) {
      case AIProviderType.hermes:
        return 'Hermes';
      case AIProviderType.firebaseAI:
        return 'Firebase AI';
    }
  }

  IconData _getProviderIcon(AIProviderType type) {
    switch (type) {
      case AIProviderType.hermes:
        return CupertinoIcons.cloud;
      case AIProviderType.firebaseAI:
        return CupertinoIcons.lightbulb;
    }
  }

  /// Create conversation lazily on first message send
  /// Returns the conversation ID so it can be set on the provider
  Future<String?> _ensureConversationExists() async {
    if (_conversationId != null || !_pendingConversation) {
      return _conversationId;
    }

    // Create conversation now
    final repository = ref.read(conversationRepositoryProvider);

    try {
      final conversation = await repository.createConversation(
        provider: _getAiProvider(_pendingProviderType!),
        model: _pendingModel!,
        promptTemplateId: _pendingTemplateId,
      );

      // Update state
      ref.read(currentConversationProvider.notifier).set(conversation);
      _conversationId = conversation.id;
      _pendingConversation = false;

      _log.info('Created conversation: ${conversation.id}');

      // Return the conversation ID so the caller can set it on the provider
      return conversation.id;
    } catch (e) {
      _log.severe('Failed to create conversation: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseProvider = ref.watch(aiChatProviderProvider);
    final currentConversation = ref.watch(currentConversationProvider);
    final currentProviderType = ref.watch(aiProviderTypeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Log which provider we're using
    _log.info(
      'Building with provider: ${baseProvider.providerName} (${baseProvider.providerId})',
    );

    // Create or reuse lazy conversation provider
    // IMPORTANT: We must reuse the same instance to avoid breaking LlmChatView's listener chain
    if (_lazyProvider == null ||
        _lazyProvider!._wrappedProvider != baseProvider) {
      _log.info(
        'Creating new LazyConversationProvider (base provider changed or first creation)',
      );

      // Dispose old lazy wrapper (but NOT the wrapped provider - that's managed by Riverpod)
      _lazyProvider?.dispose();

      // Create new lazy provider wrapper
      // Note: _firstMessageHandled is false by default, which is correct for provider switches
      _lazyProvider = _LazyConversationProvider(
        wrappedProvider: baseProvider,
        onFirstMessage: _ensureConversationExists,
      );
    }

    final provider = _lazyProvider!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentConversation?.title ?? '${provider.providerName} Chat',
        ),
        actions: [
          // Provider switcher dropdown
          PopupMenuButton<AIProviderType>(
            icon: Icon(_getProviderIcon(currentProviderType)),
            tooltip:
                'Switch AI Provider (${_getProviderDisplayName(currentProviderType)})',
            onSelected: (AIProviderType value) async {
              if (value != currentProviderType) {
                // Check if there's an active conversation with messages
                final hasMessages = provider.history.isNotEmpty;
                final messenger = ScaffoldMessenger.of(context);

                bool shouldSwitch = true;
                if (hasMessages && mounted) {
                  // Show confirmation dialog
                  shouldSwitch =
                      await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Switch AI Provider?'),
                          content: const Text(
                            'Switching providers will start a new conversation. '
                            'Your current conversation will be saved and accessible '
                            'from the conversation history.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Switch'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                }

                if (shouldSwitch) {
                  ref
                      .read(aiProviderTypeProvider.notifier)
                      .setProvider(value, reason: 'user_selection');
                  // Clear current conversation to force new provider
                  ref.read(currentConversationProvider.notifier).clear();
                  // Show snackbar to confirm switch
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Switched to ${_getProviderDisplayName(value)} - Starting new conversation',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<AIProviderType>>[
                  PopupMenuItem<AIProviderType>(
                    value: AIProviderType.hermes,
                    child: Row(
                      children: [
                        Icon(
                          _getProviderIcon(AIProviderType.hermes),
                          size: 20,
                          color: currentProviderType == AIProviderType.hermes
                              ? colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getProviderDisplayName(AIProviderType.hermes),
                          style: TextStyle(
                            color: currentProviderType == AIProviderType.hermes
                                ? colorScheme.primary
                                : null,
                            fontWeight:
                                currentProviderType == AIProviderType.hermes
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (currentProviderType == AIProviderType.hermes) ...[
                          const Spacer(),
                          Icon(
                            CupertinoIcons.check_mark,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem<AIProviderType>(
                    value: AIProviderType.firebaseAI,
                    child: Row(
                      children: [
                        Icon(
                          _getProviderIcon(AIProviderType.firebaseAI),
                          size: 20,
                          color:
                              currentProviderType == AIProviderType.firebaseAI
                              ? colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getProviderDisplayName(AIProviderType.firebaseAI),
                          style: TextStyle(
                            color:
                                currentProviderType == AIProviderType.firebaseAI
                                ? colorScheme.primary
                                : null,
                            fontWeight:
                                currentProviderType == AIProviderType.firebaseAI
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (currentProviderType ==
                            AIProviderType.firebaseAI) ...[
                          const Spacer(),
                          Icon(
                            CupertinoIcons.check_mark,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
          ),
          // Rate conversation
          if (_conversationId != null)
            IconButton(
              icon: const Icon(CupertinoIcons.star),
              onPressed: () => _showRatingDialog(context),
              tooltip: 'Rate Conversation',
            ),
          // Conversation info
          if (_conversationId != null)
            IconButton(
              icon: const Icon(CupertinoIcons.info),
              onPressed: () => _showConversationInfo(context),
              tooltip: 'Conversation Info',
            ),
          // Provider info (debugging)
          IconButton(
            icon: const Icon(CupertinoIcons.wrench),
            onPressed: () => _showProviderInfo(context),
            tooltip: 'Provider Info',
          ),
        ],
      ),
      body: CustomChatView(
        provider: provider,
        welcomeMessage:
            'Hello! I\'m ${provider.providerName}, your AI assistant. How can I help you today?',
        suggestions: const [
          'Help me with a question',
          'Analyze some text for me',
          'Explain a concept',
          'Review my work',
          'Suggest improvements',
        ],
      ),
    );
  }

  /// Show rating dialog
  Future<void> _showRatingDialog(BuildContext context) async {
    if (_conversationId == null) return;

    final repository = ref.read(conversationRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    // Load existing rating if any
    final existingRating = await repository.getRating(_conversationId!);

    if (!mounted) return;

    final result = await showDialog<ConversationRatingInput>(
      context: context,
      builder: (context) => RatingDialog(existingRating: existingRating),
    );

    if (result != null) {
      try {
        await repository.rateConversation(
          conversationId: _conversationId!,
          rating: result.rating,
          notes: result.notes,
        );

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Rating saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to save rating: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  /// Show conversation info dialog
  Future<void> _showConversationInfo(BuildContext context) async {
    final currentConversation = ref.read(currentConversationProvider);
    if (currentConversation == null) return;

    PromptTemplates? template;
    if (currentConversation.promptTemplateId != null) {
      final repository = ref.read(promptTemplateRepositoryProvider);
      try {
        final templates = await repository.getTemplates();
        template = templates.firstWhere(
          (t) => t.id == currentConversation.promptTemplateId,
          orElse: () => templates.first, // Fallback - shouldn't happen
        );
      } catch (e) {
        // Ignore error - template will be null
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => ConversationInfoDialog(
        conversation: currentConversation,
        promptTemplate: template,
      ),
    );
  }

  /// Show provider information dialog for debugging/testing
  void _showProviderInfo(BuildContext context) {
    final provider = ref.read(aiChatProviderProvider);
    final metadata = ref.read(currentProviderMetadataProvider);
    final capabilities = provider.capabilities;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Provider: ${provider.providerName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Provider ID', provider.providerId),
              _buildInfoRow('Model', provider.model ?? 'N/A'),
              if (provider.availableTools.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Available Tools',
                  provider.availableTools.length.toString(),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Capabilities:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CapabilityBadges(capabilities: capabilities),
              const SizedBox(height: 16),
              const Text(
                'Metadata:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                metadata.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Wrapper provider that intercepts first message to trigger lazy conversation creation
///
/// This ensures conversations are only created when the user actually sends a message,
/// preventing empty conversation clutter from users who browse but don't interact.
class _LazyConversationProvider extends AIChatProvider {
  final AIChatProvider _wrappedProvider;
  final Future<String?> Function() _onFirstMessage;
  bool _firstMessageHandled = false;

  _LazyConversationProvider({
    required AIChatProvider wrappedProvider,
    required Future<String?> Function() onFirstMessage,
  }) : _wrappedProvider = wrappedProvider,
       _onFirstMessage = onFirstMessage {
    _wrappedProvider.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _wrappedProvider.removeListener(notifyListeners);
    // DO NOT dispose the wrapped provider - it's managed by Riverpod!
    // Only remove our listener to prevent memory leaks
    super.dispose();
  }

  @override
  Stream<String> sendMessageStream(String prompt) async* {
    // Create conversation on first message (or ensure it exists)
    if (!_firstMessageHandled) {
      _firstMessageHandled = true;
      _log.info('LazyConversationProvider: Handling first message');
      final conversationId = await _onFirstMessage();

      // CRITICAL: Set conversation ID on wrapped provider BEFORE forwarding
      // This ensures ConversationAwareProvider can save messages
      if (conversationId != null) {
        _log.info(
          'LazyConversationProvider: Setting conversation ID: $conversationId',
        );
        _wrappedProvider.setConversationId(conversationId);
      } else {
        _log.warning(
          'LazyConversationProvider: No conversation ID returned from first message handler',
        );
      }
    } else {
      // If this is not the first message, ensure conversation ID is still set
      // (handles case where widget rebuilt and created new _LazyConversationProvider)
      final conversationId = await _onFirstMessage();
      if (conversationId != null && _wrappedProvider.conversationId == null) {
        _log.warning(
          'LazyConversationProvider: Conversation ID was null on wrapped provider, setting it to: $conversationId',
        );
        _wrappedProvider.setConversationId(conversationId);
      }
    }

    // Forward to wrapped provider
    _log.fine(
      'LazyConversationProvider: Forwarding to wrapped provider (conversationId: ${_wrappedProvider.conversationId})',
    );
    yield* _wrappedProvider.sendMessageStream(prompt);
  }

  @override
  List<ChatMessage> get history => _wrappedProvider.history;

  @override
  set history(List<ChatMessage> value) => _wrappedProvider.history = value;

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
    'wrapper': 'LazyConversationProvider',
  };
}
