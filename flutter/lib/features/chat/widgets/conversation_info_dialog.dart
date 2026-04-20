import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../data/models/models.dart';

/// Dialog showing conversation metadata
///
/// Displays:
/// - Provider and model information
/// - Message count
/// - Creation and last update dates
/// - Prompt template used (if any)
class ConversationInfoDialog extends StatelessWidget {
  final Conversations conversation;
  final PromptTemplates? promptTemplate;

  const ConversationInfoDialog({
    super.key,
    required this.conversation,
    this.promptTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Conversation Info'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _InfoRow(
              label: 'Title',
              value: conversation.title ?? 'Untitled Conversation',
              icon: CupertinoIcons.textformat,
            ),
            const Divider(),

            // Provider
            _InfoRow(
              label: 'Provider',
              value: _formatProvider(conversation.provider),
              icon: CupertinoIcons.cloud,
            ),
            const SizedBox(height: 12),

            // Model
            _InfoRow(
              label: 'Model',
              value: conversation.model,
              icon: CupertinoIcons.lightbulb,
            ),
            const SizedBox(height: 12),

            // Message count
            _InfoRow(
              label: 'Messages',
              value: '${conversation.messageCount}',
              icon: CupertinoIcons.chat_bubble,
            ),
            const Divider(),

            // Prompt template
            if (promptTemplate != null) ...[
              _InfoRow(
                label: 'Template',
                value: promptTemplate!.name,
                icon: CupertinoIcons.doc,
              ),
              if (promptTemplate!.description != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4),
                  child: Text(
                    promptTemplate!.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],

            // Created date
            _InfoRow(
              label: 'Created',
              value: _formatDateTime(conversation.createdAt),
              icon: CupertinoIcons.clock,
            ),
            const SizedBox(height: 12),

            // Last updated
            _InfoRow(
              label: 'Last Updated',
              value: _formatDateTime(conversation.updatedAt),
              icon: CupertinoIcons.arrow_clockwise,
            ),

            // Archived status
            if (conversation.isArchived) ...[
              const Divider(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.archivebox_fill,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'This conversation is archived',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatProvider(dynamic provider) {
    // Handle either AiProvider enum variant
    final providerValue = provider.toString().contains('hermes')
        ? 'hermes'
        : 'firebase_ai';
    switch (providerValue) {
      case 'hermes':
        return 'Hermes Agent';
      case 'firebase_ai':
        return 'Firebase AI';
      default:
        return provider.toString();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${months[local.month - 1]} ${local.day}, ${local.year} at $displayHour:$minute $period';
  }
}

/// Info row widget showing a label, icon, and value
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
