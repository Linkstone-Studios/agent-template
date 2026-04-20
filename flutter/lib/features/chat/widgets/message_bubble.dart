import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/chat_attachment.dart';

/// Professional message bubble with timestamp and status
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;
  final bool animate;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.origin == MessageOrigin.user;
    final isSystem = message.origin == MessageOrigin.system;

    if (isSystem) {
      return _buildSystemMessage(context);
    }

    final bubble = Container(
      margin: EdgeInsets.only(
        left: isUser ? 64 : 8,
        right: isUser ? 8 : 64,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isUser
                ? _buildUserContent(context)
                : _buildAssistantContent(context),
          ),
          if (showTimestamp) ...[
            const SizedBox(height: 4),
            _buildTimestamp(context, isUser),
          ],
        ],
      ),
    );

    if (!animate) return bubble;

    // Animate message appearance
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: bubble,
    );
  }

  Widget _buildUserContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attachments (if any)
        if (message.attachments != null && message.attachments!.isNotEmpty)
          ..._buildAttachments(context, forUser: true),

        // Message text
        if (message.text.isNotEmpty)
          Text(
            message.text,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 16,
              height: 1.4,
            ),
          ),
      ],
    );
  }

  Widget _buildAssistantContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Don't show empty streaming messages - the list-level loading indicator handles this
    if (message.status == MessageStatus.streaming &&
        message.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Show error message with better visibility
    if (message.status == MessageStatus.failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Message failed',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.text,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return MarkdownBody(
      data: message.text,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: colorScheme.onSurface, fontSize: 16, height: 1.4),
        code: TextStyle(
          color: colorScheme.onSurface,
          backgroundColor: colorScheme.surfaceContainerHigh,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        a: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.text,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context, bool isUser) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeFormat = DateFormat('h:mm a');
    final timestampText = timeFormat.format(message.timestamp);

    return Padding(
      padding: EdgeInsets.only(left: isUser ? 0 : 16, right: isUser ? 16 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timestampText,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          if (message.status == MessageStatus.failed) ...[
            const SizedBox(width: 6),
            Icon(Icons.error_outline, size: 14, color: colorScheme.error),
          ],
          if (message.status == MessageStatus.sending) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(
                  colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildAttachments(
    BuildContext context, {
    required bool forUser,
  }) {
    final attachments = message.attachments!;

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: attachments.map((attachment) {
            return _buildAttachmentCard(context, attachment, forUser: forUser);
          }).toList(),
        ),
      ),
    ];
  }

  Widget _buildAttachmentCard(
    BuildContext context,
    ChatAttachment attachment, {
    required bool forUser,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: forUser
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: forUser
              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.2)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForAttachmentType(attachment.type),
            size: 24,
            color: forUser
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: forUser
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.fileSizeBytes != null)
                  Text(
                    _formatFileSize(attachment.fileSizeBytes!),
                    style: TextStyle(
                      fontSize: 10,
                      color: forUser
                          ? colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            )
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAttachmentType(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf;
      case AttachmentType.document:
        return Icons.description;
      case AttachmentType.other:
        return Icons.attach_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
