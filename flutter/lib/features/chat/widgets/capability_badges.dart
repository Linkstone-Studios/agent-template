import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:agent_template/features/chat/providers/ai_chat_provider.dart';

/// Widget that displays capability badges for an AI provider
///
/// Shows which features the provider supports (streaming, tools, multimodal, etc.)
/// with visual indicators (checkmarks or crosses).
class CapabilityBadges extends StatelessWidget {
  final ProviderCapabilities capabilities;
  final bool compact;

  const CapabilityBadges({
    super.key,
    required this.capabilities,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (compact) {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          if (capabilities.supportsStreaming)
            _buildBadge(
              context,
              CupertinoIcons.arrow_down_to_line,
              'Streaming',
            ),
          if (capabilities.supportsTools)
            _buildBadge(context, CupertinoIcons.hammer, 'Tools'),
          if (capabilities.supportsMultimodal)
            _buildBadge(context, CupertinoIcons.photo, 'Multimodal'),
          if (capabilities.supportsVision)
            _buildBadge(context, CupertinoIcons.eye, 'Vision'),
          if (capabilities.supportsAudio)
            _buildBadge(context, CupertinoIcons.mic, 'Audio'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCapabilityRow(
          context,
          'Streaming',
          capabilities.supportsStreaming,
          CupertinoIcons.arrow_down_to_line,
        ),
        const SizedBox(height: 8),
        _buildCapabilityRow(
          context,
          'Tools/Functions',
          capabilities.supportsTools,
          CupertinoIcons.hammer,
        ),
        const SizedBox(height: 8),
        _buildCapabilityRow(
          context,
          'Multimodal',
          capabilities.supportsMultimodal,
          CupertinoIcons.photo,
        ),
        const SizedBox(height: 8),
        _buildCapabilityRow(
          context,
          'Vision',
          capabilities.supportsVision,
          CupertinoIcons.eye,
        ),
        const SizedBox(height: 8),
        _buildCapabilityRow(
          context,
          'Audio',
          capabilities.supportsAudio,
          CupertinoIcons.mic,
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Max Tokens: ${capabilities.maxTokens}',
          style: theme.textTheme.bodySmall,
        ),
        if (capabilities.supportedModels.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Models: ${capabilities.supportedModels.join(', ')}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      avatar: Icon(icon, size: 16, color: colorScheme.onSecondaryContainer),
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall,
      backgroundColor: colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildCapabilityRow(
    BuildContext context,
    String label,
    bool supported,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          supported
              ? CupertinoIcons.checkmark_circle_fill
              : CupertinoIcons.xmark_circle_fill,
          color: supported ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: supported
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
