import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../providers/usage_stats_provider.dart';

/// Example widget showing how to use the typed repositories and models
/// This displays the user's AI usage statistics in a card
class UsageStatsCard extends ConsumerWidget {
  const UsageStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageStatsAsync = ref.watch(currentUserUsageStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: usageStatsAsync.when(
          data: (stats) {
            if (stats == null) {
              return const Text('No usage data available');
            }
            return _buildStatsContent(stats);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildStatsContent(UsageStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Usage Statistics',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildStatRow('Total API Calls', stats.totalCalls.toString()),
        _buildStatRow('Input Tokens', _formatNumber(stats.totalInputTokens)),
        _buildStatRow('Output Tokens', _formatNumber(stats.totalOutputTokens)),
        _buildStatRow('Total Cost', '\$${stats.totalCost.toStringAsFixed(4)}'),
        const Divider(height: 24),
        Text(
          'Provider Breakdown',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildStatRow('Hermes Usage', stats.hermesUsage.toString()),
        _buildStatRow('Firebase AI Usage', stats.firebaseAiUsage.toString()),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toString();
  }
}

/// Example widget showing recent usage logs
class RecentUsageLogsWidget extends ConsumerWidget {
  const RecentUsageLogsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(recentUsageLogsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Text('No activity yet');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogItem(log);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(AiUsageLogs log) {
    // Using the typed enum directly
    final providerIcon = log.provider == AiProvider.hermes
        ? CupertinoIcons.lightbulb
        : CupertinoIcons.sparkles;

    final providerColor = log.provider == AiProvider.hermes
        ? Colors.purple
        : Colors.blue;

    return ListTile(
      leading: Icon(providerIcon, color: providerColor),
      title: Text(log.model),
      subtitle: Text(
        '${log.inputTokens ?? 0} in / ${log.outputTokens ?? 0} out',
      ),
      trailing: log.costUsd != null
          ? Text('\$${log.costUsd!.toStringAsFixed(4)}')
          : null,
    );
  }
}
