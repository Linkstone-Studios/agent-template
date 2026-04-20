import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../providers/conversation_providers.dart';
import '../widgets/new_conversation_dialog.dart';

/// Conversation list screen showing all user's conversations
///
/// Displays conversations with metadata (provider, model, message count, date).
/// Allows creating new conversations and resuming existing ones.
class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(
      conversationListProvider(includeArchived: false),
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus),
            onPressed: () => _createNewConversation(context, ref),
            tooltip: 'New Conversation',
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new conversation to begin',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _createNewConversation(context, ref),
                    icon: const Icon(CupertinoIcons.plus),
                    label: const Text('New Conversation'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _ConversationCard(
                conversation: conv,
                onTap: () => _openConversation(context, ref, conv),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading conversations',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNewConversation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<NewConversationConfig>(
      context: context,
      builder: (context) => const NewConversationDialog(),
    );

    if (result != null && context.mounted) {
      // Clear current conversation and set template selection
      ref.read(currentConversationProvider.notifier).clear();
      if (result.promptTemplate != null) {
        ref
            .read(selectedPromptTemplateProvider.notifier)
            .select(result.promptTemplate);
      } else {
        ref.read(selectedPromptTemplateProvider.notifier).clear();
      }

      // Navigate to chat screen (conversation will be created there)
      context.go('/chat');
    }
  }

  void _openConversation(
    BuildContext context,
    WidgetRef ref,
    Conversations conv,
  ) {
    // Set the current conversation
    ref.read(currentConversationProvider.notifier).set(conv);
    ref.read(selectedPromptTemplateProvider.notifier).clear();

    // Navigate to chat screen
    context.go('/chat');
  }
}

/// Card widget for displaying a conversation in the list
class _ConversationCard extends ConsumerWidget {
  final Conversations conversation;
  final VoidCallback onTap;

  const _ConversationCard({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Left section: Icon and conversation info
              Expanded(
                child: Row(
                  children: [
                    // Conversation icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.title ?? 'Untitled Conversation',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _InfoLabel(
                                icon: CupertinoIcons.sparkles,
                                label: _formatProviderName(
                                  conversation.provider,
                                ),
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _InfoLabel(
                                icon: CupertinoIcons.chat_bubble,
                                label: '${conversation.messageCount}',
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Right section: Date and menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(conversation.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dropdown menu button
                  PopupMenuButton<String>(
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Options',
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'rename',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.pencil,
                              size: 18,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Text('Rename', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'archive',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.archivebox,
                              size: 18,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Text('Archive', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'delete',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.trash,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _showRenameDialog(context, ref);
                          break;
                        case 'archive':
                          _archiveConversation(context, ref);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, ref);
                          break;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show rename dialog
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: conversation.title ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Enter conversation title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final repository = ref.read(conversationRepositoryProvider);
        await repository.updateTitle(conversation.id, result);

        // Refresh conversation list
        ref.invalidate(conversationListProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Conversation renamed')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to rename: $e')));
        }
      }
    }
  }

  /// Archive conversation
  Future<void> _archiveConversation(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(conversationRepositoryProvider);
      await repository.archiveConversation(conversation.id);

      // Refresh conversation list
      ref.invalidate(conversationListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Conversation archived'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await repository.unarchiveConversation(conversation.id);
                ref.invalidate(conversationListProvider);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to archive: $e')));
      }
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(conversationRepositoryProvider);
        await repository.deleteConversation(conversation.id);

        // Refresh conversation list
        ref.invalidate(conversationListProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Conversation deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  String _formatProviderName(dynamic provider) {
    // Handle either AiProvider enum variant
    final providerValue = provider.toString().contains('hermes')
        ? 'hermes'
        : 'firebase_ai';
    switch (providerValue) {
      case 'hermes':
        return 'Hermes';
      case 'firebase_ai':
        return 'Firebase AI';
      default:
        return provider.toString();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
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
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}

/// Small label widget for displaying metadata with icon
class _InfoLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _InfoLabel({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
