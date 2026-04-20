import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../providers/ai_provider_factory.dart';
import '../providers/conversation_providers.dart';

/// Configuration for a new conversation
class NewConversationConfig {
  final AIProviderType providerType;
  final PromptTemplates? promptTemplate;

  NewConversationConfig({required this.providerType, this.promptTemplate});
}

/// Dialog for creating a new conversation
///
/// Allows user to select:
/// - AI Provider (Hermes or Firebase AI)
/// - Prompt Template (optional)
class NewConversationDialog extends ConsumerStatefulWidget {
  const NewConversationDialog({super.key});

  @override
  ConsumerState<NewConversationDialog> createState() =>
      _NewConversationDialogState();
}

class _NewConversationDialogState extends ConsumerState<NewConversationDialog> {
  late AIProviderType _selectedProvider;
  PromptTemplates? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    // Start with current provider type
    _selectedProvider = ref.read(aiProviderTypeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(promptTemplatesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('New Conversation'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider selector
            Text('AI Provider', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<AIProviderType>(
              segments: const [
                ButtonSegment<AIProviderType>(
                  value: AIProviderType.hermes,
                  label: Text('Hermes'),
                  icon: Icon(CupertinoIcons.cloud),
                ),
                ButtonSegment<AIProviderType>(
                  value: AIProviderType.firebaseAI,
                  label: Text('Firebase AI'),
                  icon: Icon(CupertinoIcons.lightbulb),
                ),
              ],
              selected: {_selectedProvider},
              onSelectionChanged: (Set<AIProviderType> newSelection) {
                setState(() {
                  _selectedProvider = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Prompt template selector
            Text(
              'Prompt Template (Optional)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.info_circle,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No templates available. Using default prompt.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return DropdownButtonFormField<PromptTemplates?>(
                  initialValue: _selectedTemplate,
                  decoration: const InputDecoration(
                    hintText: 'Default (no template)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<PromptTemplates?>(
                      value: null,
                      child: Text('Default (no template)'),
                    ),
                    ...templates.map((template) {
                      return DropdownMenuItem<PromptTemplates?>(
                        value: template,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              template.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (template.description != null)
                              Text(
                                template.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTemplate = value);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load templates',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              NewConversationConfig(
                providerType: _selectedProvider,
                promptTemplate: _selectedTemplate,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
