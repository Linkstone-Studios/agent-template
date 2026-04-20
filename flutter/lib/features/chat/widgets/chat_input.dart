import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_attachment.dart';
import 'attachment_picker.dart';

/// Professional chat input widget with file attachment support
class ChatInput extends StatefulWidget {
  final Function(String message, List<ChatAttachment>? attachments)
  onSendMessage;
  final bool enabled;
  final String? hintText;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;
  final List<ChatAttachment> _attachments = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    widget.onSendMessage(
      text,
      _attachments.isNotEmpty ? List.from(_attachments) : null,
    );
    _controller.clear();
    setState(() {
      _hasText = false;
      _attachments.clear();
    });
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentPicker(onFilesPicked: _handleFilesPicked),
    );
  }

  void _handleFilesPicked(List<XFile> files) {
    final newAttachments = files.map((file) {
      return ChatAttachment.fromLocal(
        id:
            DateTime.now().millisecondsSinceEpoch.toString() +
            files.indexOf(file).toString(),
        fileName: file.name,
        localPath: file.path,
        mimeType: file.mimeType,
        fileSizeBytes: file.length().then((v) => v).hashCode, // approximation
      );
    }).toList();

    setState(() {
      _attachments.addAll(newAttachments);
    });
  }

  void _removeAttachment(ChatAttachment attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSend = (_hasText || _attachments.isNotEmpty) && widget.enabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachment previews
            if (_attachments.isNotEmpty)
              Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    final attachment = _attachments[index];
                    return _buildAttachmentPreview(attachment, colorScheme);
                  },
                ),
              ),

            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                Container(
                  height: 48,
                  width: 48,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: widget.enabled ? _showAttachmentPicker : null,
                    icon: Icon(
                      Icons.add_rounded,
                      color: widget.enabled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    tooltip: 'Add attachment',
                  ),
                ),

                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: TextField(
                      controller: _controller,
                      enabled: widget.enabled,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (text) {
                        final hasText = text.trim().isNotEmpty;
                        if (hasText != _hasText) {
                          setState(() => _hasText = hasText);
                        }
                      },
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                ),

                // Send button
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: canSend
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: canSend ? _handleSubmit : null,
                    icon: Icon(
                      Icons.send_rounded,
                      color: canSend
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    tooltip: 'Send',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(
    ChatAttachment attachment,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForAttachmentType(attachment.type),
                  color: colorScheme.onSurfaceVariant,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  attachment.fileName.length > 10
                      ? '${attachment.fileName.substring(0, 7)}...'
                      : attachment.fileName,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removeAttachment(attachment),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: colorScheme.onErrorContainer,
                ),
              ),
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
}
