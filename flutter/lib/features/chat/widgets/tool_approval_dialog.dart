import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:agent_template/features/chat/tools/base_tool.dart';

/// Dialog for requesting user approval before executing a tool
///
/// Shows tool information, parameters, and allows user to approve/deny.
/// Includes "remember my choice" option for future executions.
class ToolApprovalDialog extends StatefulWidget {
  final AIChatTool tool;
  final Map<String, dynamic> arguments;
  final VoidCallback? onRememberChoice;

  const ToolApprovalDialog({
    super.key,
    required this.tool,
    required this.arguments,
    this.onRememberChoice,
  });

  @override
  State<ToolApprovalDialog> createState() => _ToolApprovalDialogState();

  /// Show the dialog and return true if approved, false if denied
  static Future<bool> show({
    required BuildContext context,
    required AIChatTool tool,
    required Map<String, dynamic> arguments,
    VoidCallback? onRememberChoice,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ToolApprovalDialog(
        tool: tool,
        arguments: arguments,
        onRememberChoice: onRememberChoice,
      ),
    );
    return result ?? false;
  }
}

class _ToolApprovalDialogState extends State<ToolApprovalDialog> {
  bool _rememberChoice = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        _getCategoryIcon(widget.tool.category),
        size: 32,
        color: _getCostColor(widget.tool.costLevel, colorScheme),
      ),
      title: Text('Approve Tool Execution?'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tool name
            Text(
              widget.tool.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Tool description
            Text(widget.tool.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),

            // Cost indicator
            _buildCostIndicator(theme, colorScheme),
            const SizedBox(height: 16),

            // Parameters
            if (widget.arguments.isNotEmpty) ...[
              Text('Parameters:', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              ...widget.arguments.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Remember choice checkbox
            CheckboxListTile(
              value: _rememberChoice,
              onChanged: (value) {
                setState(() {
                  _rememberChoice = value ?? false;
                });
              },
              title: Text(
                'Always allow this tool',
                style: theme.textTheme.bodySmall,
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Deny'),
        ),
        FilledButton(
          onPressed: () {
            if (_rememberChoice) {
              widget.onRememberChoice?.call();
            }
            Navigator.of(context).pop(true);
          },
          child: const Text('Approve'),
        ),
      ],
    );
  }

  Widget _buildCostIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCostColor(
          widget.tool.costLevel,
          colorScheme,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getCostColor(
            widget.tool.costLevel,
            colorScheme,
          ).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCostIcon(widget.tool.costLevel),
            size: 16,
            color: _getCostColor(widget.tool.costLevel, colorScheme),
          ),
          const SizedBox(width: 6),
          Text(
            _getCostLabel(widget.tool.costLevel),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getCostColor(widget.tool.costLevel, colorScheme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'computation':
        return CupertinoIcons.sum;
      case 'search':
        return CupertinoIcons.search;
      case 'communication':
        return CupertinoIcons.paperplane;
      case 'file_system':
        return CupertinoIcons.folder;
      case 'database':
        return CupertinoIcons.folder_fill;
      default:
        return CupertinoIcons.hammer;
    }
  }

  IconData _getCostIcon(ToolCostLevel costLevel) {
    switch (costLevel) {
      case ToolCostLevel.free:
        return CupertinoIcons.checkmark_circle_fill;
      case ToolCostLevel.low:
        return CupertinoIcons.info_circle_fill;
      case ToolCostLevel.medium:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case ToolCostLevel.high:
        return CupertinoIcons.exclamationmark_circle_fill;
    }
  }

  String _getCostLabel(ToolCostLevel costLevel) {
    switch (costLevel) {
      case ToolCostLevel.free:
        return 'Free';
      case ToolCostLevel.low:
        return 'Low Cost';
      case ToolCostLevel.medium:
        return 'Medium Cost';
      case ToolCostLevel.high:
        return 'High Cost';
    }
  }

  Color _getCostColor(ToolCostLevel costLevel, ColorScheme colorScheme) {
    switch (costLevel) {
      case ToolCostLevel.free:
        return Colors.green;
      case ToolCostLevel.low:
        return Colors.blue;
      case ToolCostLevel.medium:
        return Colors.orange;
      case ToolCostLevel.high:
        return Colors.red;
    }
  }
}
