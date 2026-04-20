import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:agent_template/features/chat/providers/ai_chat_provider.dart';

/// Widget that displays a tool call indicator in chat messages
///
/// Shows when a tool/function is being called or has been executed
/// with visual feedback about the tool name and result.
class ToolCallIndicator extends StatelessWidget {
  final ToolResult result;
  final bool isLoading;

  const ToolCallIndicator({
    super.key,
    required this.result,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color color;
    Color backgroundColor;

    if (isLoading) {
      icon = CupertinoIcons.arrow_2_circlepath;
      color = colorScheme.primary;
      backgroundColor = colorScheme.primaryContainer;
    } else if (result.success) {
      icon = CupertinoIcons.checkmark_circle_fill;
      color = Colors.green;
      backgroundColor = Colors.green.withValues(alpha: 0.1);
    } else {
      icon = CupertinoIcons.exclamationmark_circle_fill;
      color = Colors.red;
      backgroundColor = Colors.red.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getToolIcon(result.toolName), size: 16, color: color),
                    const SizedBox(width: 4),
                    Text(
                      _formatToolName(result.toolName),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.displayText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                if (result.error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${result.error}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getToolIcon(String toolName) {
    switch (toolName) {
      case 'calculator':
      case 'psychometric_calculator':
        return CupertinoIcons.sum;
      default:
        return CupertinoIcons.hammer;
    }
  }

  String _formatToolName(String toolName) {
    // Convert snake_case to Title Case
    return toolName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// A compact version of the tool call indicator for inline display
class CompactToolCallIndicator extends StatelessWidget {
  final String toolName;

  const CompactToolCallIndicator({super.key, required this.toolName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      avatar: Icon(_getToolIcon(toolName), size: 14),
      label: Text(_formatToolName(toolName), style: theme.textTheme.labelSmall),
      backgroundColor: colorScheme.secondaryContainer,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  IconData _getToolIcon(String toolName) {
    switch (toolName) {
      case 'calculator':
      case 'psychometric_calculator':
        return CupertinoIcons.sum;
      default:
        return CupertinoIcons.hammer;
    }
  }

  String _formatToolName(String toolName) {
    return toolName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
