import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import '../../../data/services/storage_service.dart';
import '../models/chat_attachment.dart';
import '../models/chat_message.dart';
import '../providers/ai_chat_provider.dart';
import 'chat_input.dart';
import 'message_list_view.dart';

final _log = Logger('CustomChatView');

/// Custom chat view with professional welcome screen and our custom UI
class CustomChatView extends ConsumerStatefulWidget {
  final AIChatProvider provider;
  final String welcomeMessage;
  final List<String> suggestions;

  const CustomChatView({
    super.key,
    required this.provider,
    required this.welcomeMessage,
    this.suggestions = const [],
  });

  @override
  ConsumerState<CustomChatView> createState() => _CustomChatViewState();
}

class _CustomChatViewState extends ConsumerState<CustomChatView> {
  bool _isStreaming = false;
  final List<String> _messageQueue = [];
  final List<ChatAttachment> _attachmentQueue = [];
  bool _isProcessingQueue = false;

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_handleProviderUpdate);
  }

  @override
  void didUpdateWidget(CustomChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle provider change - critical for provider switching to work correctly
    if (widget.provider != oldWidget.provider) {
      oldWidget.provider.removeListener(_handleProviderUpdate);
      widget.provider.addListener(_handleProviderUpdate);
      // Force update to reflect new provider's state
      _handleProviderUpdate();
    }
  }

  @override
  void dispose() {
    widget.provider.removeListener(_handleProviderUpdate);
    super.dispose();
  }

  void _handleProviderUpdate() {
    // Check if currently streaming (last message is streaming)
    final history = widget.provider.history;
    final newIsStreaming =
        history.isNotEmpty && history.last.status == MessageStatus.streaming;

    if (newIsStreaming != _isStreaming) {
      setState(() => _isStreaming = newIsStreaming);

      // If streaming finished, process any queued messages
      if (!newIsStreaming && !_isProcessingQueue && _messageQueue.isNotEmpty) {
        _processMessageQueue();
      }
    }
  }

  Future<void> _handleSendMessage(
    String text,
    List<ChatAttachment>? attachments,
  ) async {
    if (text.trim().isEmpty && (attachments == null || attachments.isEmpty)) {
      return;
    }

    // If currently streaming, queue the message
    if (_isStreaming || _isProcessingQueue) {
      setState(() {
        _messageQueue.add(text);
        if (attachments != null && attachments.isNotEmpty) {
          _attachmentQueue.addAll(attachments);
        }
      });
      _log.info('Queued message (${_messageQueue.length} in queue)');

      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message queued (${_messageQueue.length} waiting)'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await _sendMessage(text, attachments);
  }

  Future<void> _sendMessage(
    String text,
    List<ChatAttachment>? attachments,
  ) async {
    _log.fine(
      'Sending message: $text with ${attachments?.length ?? 0} attachments',
    );

    // Upload attachments first if any
    List<ChatAttachment>? uploadedAttachments;
    if (attachments != null && attachments.isNotEmpty) {
      try {
        uploadedAttachments = await _uploadAttachments(attachments);
      } catch (e) {
        _log.severe('Failed to upload attachments: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload attachments: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    // Build message text with attachment info if present
    String messageText = text;
    if (uploadedAttachments != null && uploadedAttachments.isNotEmpty) {
      // For now, append attachment URLs to the message
      // TODO: Update AI providers to accept structured attachment data
      messageText += '\n\n[Attachments]:';
      for (final attachment in uploadedAttachments) {
        messageText += '\n- ${attachment.fileName}: ${attachment.publicUrl}';
      }
    }

    try {
      // Stream the response
      // Provider will add user message to history automatically
      await for (final _ in widget.provider.sendMessageStream(messageText)) {
        // Provider updates history automatically, UI updates via listener
      }
    } catch (e) {
      _log.severe('Error sending message: $e');
      // Error is already added to history by provider

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _sendMessage(text, uploadedAttachments),
            ),
          ),
        );
      }
    }
  }

  Future<List<ChatAttachment>> _uploadAttachments(
    List<ChatAttachment> attachments,
  ) async {
    final storageService = ref.read(storageServiceProvider.notifier);
    final uploadedAttachments = <ChatAttachment>[];

    for (final attachment in attachments) {
      if (attachment.localPath == null) continue;

      try {
        final file = XFile(attachment.localPath!);
        final result = await storageService.uploadFile(
          bucket: StorageBuckets.chatAttachments,
          file: file,
          folder: 'conversation_attachments',
        );

        final uploaded = attachment.copyWith(
          storagePath: result.path,
          publicUrl: result.publicUrl,
          uploadStatus: AttachmentUploadStatus.uploaded,
        );

        uploadedAttachments.add(uploaded);
        _log.info(
          'Uploaded attachment: ${attachment.fileName} -> ${result.publicUrl}',
        );
      } catch (e) {
        _log.severe('Failed to upload ${attachment.fileName}: $e');
        rethrow;
      }
    }

    return uploadedAttachments;
  }

  Future<void> _processMessageQueue() async {
    if (_messageQueue.isEmpty || _isProcessingQueue) return;

    setState(() => _isProcessingQueue = true);

    while (_messageQueue.isNotEmpty) {
      final nextMessage = _messageQueue.removeAt(0);
      // Process queued messages with their attachments
      // For simplicity, queued messages don't have attachments yet
      await _sendMessage(nextMessage, null);

      // Small delay between queued messages
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() => _isProcessingQueue = false);
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.provider.history;
    final isEmpty = history.isEmpty;
    final hasQueuedMessages = _messageQueue.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: MessageListView(
            messages: history,
            isLoading: _isStreaming,
            emptyWidget: isEmpty ? _buildWelcomeScreen() : null,
          ),
        ),
        // Show queue indicator if messages are queued
        if (hasQueuedMessages)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_messageQueue.length} message${_messageQueue.length == 1 ? '' : 's'} queued',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ChatInput(
          onSendMessage: _handleSendMessage,
          enabled: true, // Always enabled - we handle queueing internally
          hintText: hasQueuedMessages
              ? 'Message will be queued...'
              : 'Type a message...',
        ),
      ],
    );
  }

  Widget _buildWelcomeScreen() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assistant_rounded, size: 64, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              widget.welcomeMessage,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            if (widget.suggestions.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Try asking:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: widget.suggestions
                    .map(
                      (suggestion) => ActionChip(
                        label: Text(suggestion),
                        onPressed: () => _handleSendMessage(suggestion, null),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
