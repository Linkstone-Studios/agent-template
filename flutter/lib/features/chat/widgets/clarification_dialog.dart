import 'package:flutter/material.dart';
import '../models/chat_message.dart';

/// Professional dialog for AI clarification requests
class ClarificationDialog extends StatefulWidget {
  final ClarificationRequest request;
  final Function(ClarificationResponse) onResponse;

  const ClarificationDialog({
    super.key,
    required this.request,
    required this.onResponse,
  });

  @override
  State<ClarificationDialog> createState() => _ClarificationDialogState();

  /// Show the clarification dialog
  static Future<ClarificationResponse?> show({
    required BuildContext context,
    required ClarificationRequest request,
  }) {
    return showDialog<ClarificationResponse>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ClarificationDialog(
        request: request,
        onResponse: (response) => Navigator.of(context).pop(response),
      ),
    );
  }
}

class _ClarificationDialogState extends State<ClarificationDialog> {
  String? selectedOption;
  final customInputController = TextEditingController();
  bool useCustomInput = false;

  @override
  void dispose() {
    customInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.help_outline, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quick Question',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.request.question,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            if (widget.request.hint != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.request.hint!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (widget.request.options != null &&
                widget.request.options!.isNotEmpty) ...[
              Text(
                'Choose an option:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.request.options!.map(
                (option) => _buildOptionTile(option),
              ),
            ],
            if (widget.request.allowCustomInput) ...[
              if (widget.request.options != null &&
                  widget.request.options!.isNotEmpty)
                const SizedBox(height: 16),
              Text(
                widget.request.options != null &&
                        widget.request.options!.isNotEmpty
                    ? 'Or provide your own:'
                    : 'Your answer:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: customInputController,
                decoration: InputDecoration(
                  hintText: 'Type your response...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    useCustomInput = value.isNotEmpty;
                    if (useCustomInput) selectedOption = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: _canSubmit() ? _handleSubmit : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String option) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedOption == option;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              selectedOption = option;
              useCustomInput = false;
              customInputController.clear();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    if (useCustomInput && customInputController.text.trim().isNotEmpty) {
      return true;
    }
    if (selectedOption != null) {
      return true;
    }
    return false;
  }

  void _handleSubmit() {
    final response = ClarificationResponse(
      requestId: widget.request.id,
      response: useCustomInput
          ? customInputController.text.trim()
          : selectedOption!,
      isFromOptions: !useCustomInput,
    );
    widget.onResponse(response);
  }
}
