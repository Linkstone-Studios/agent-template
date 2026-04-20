import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_providers.dart';

/// Analytics Dashboard Screen
///
/// Displays key metrics for AI provider performance and prompt template effectiveness.
/// Used for internal testing and optimization of AI configurations.
class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Performance Analytics'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate all analytics providers to refresh data
          ref.invalidate(providerRatingStatsProvider);
          ref.invalidate(templateRatingStatsProvider);
          ref.invalidate(templateUsageStatsProvider);
          ref.invalidate(providerUsageOverTimeProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text(
              'Performance Insights',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Compare AI providers and prompt templates for AI tasks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Key Metrics Cards
            const _KeyMetricsSection(),
            const SizedBox(height: 24),

            // Provider Performance
            const _ProviderPerformanceSection(),
            const SizedBox(height: 24),

            // Template Effectiveness
            const _TemplateEffectivenessSection(),
            const SizedBox(height: 24),

            // Template Usage Stats
            const _TemplateUsageSection(),
          ],
        ),
      ),
    );
  }
}

/// Key metrics at a glance
class _KeyMetricsSection extends ConsumerWidget {
  const _KeyMetricsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestProviderAsync = ref.watch(bestPerformingProviderProvider);
    final bestTemplateAsync = ref.watch(mostEffectiveTemplateProvider);
    final satisfactionAsync = ref.watch(overallSatisfactionRateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Best Provider',
                valueAsync: bestProviderAsync,
                icon: CupertinoIcons.sparkles,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Satisfaction',
                valueAsync: satisfactionAsync.when(
                  data: (rate) =>
                      AsyncValue.data('${rate.toStringAsFixed(1)}%'),
                  loading: () => const AsyncValue.loading(),
                  error: (e, s) => AsyncValue.error(e, s),
                ),
                icon: CupertinoIcons.hand_thumbsup,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Top Template',
          valueAsync: bestTemplateAsync,
          icon: CupertinoIcons.lightbulb,
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final AsyncValue<String?> valueAsync;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.valueAsync,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            valueAsync.when(
              data: (value) => Text(
                value ?? 'N/A',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) =>
                  const Text('Error'), // ignore: avoid_types_as_parameter_names
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider performance comparison
class _ProviderPerformanceSection extends ConsumerWidget {
  const _ProviderPerformanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(providerRatingStatsProvider(limitDays: 30));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider Performance (Last 30 Days)',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) {
            if (stats.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No rating data available yet')),
                ),
              );
            }

            // Group by provider
            final providerGroups = <String, List<dynamic>>{};
            for (final stat in stats) {
              providerGroups.putIfAbsent(stat.provider, () => []).add(stat);
            }

            return Column(
              children: providerGroups.entries.map((entry) {
                final provider = entry.key;
                final providerStats = entry.value;
                final avgRating =
                    providerStats
                        .map((s) => s.avgRating)
                        .reduce((a, b) => a + b) /
                    providerStats.length;
                final totalConversations = providerStats
                    .map((s) => s.ratedConversations)
                    .reduce((a, b) => a + b);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getProviderColor(provider),
                      child: Text(
                        provider[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(_formatProviderName(provider)),
                    subtitle: Text('$totalConversations rated conversations'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.star_fill,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              avgRating.toStringAsFixed(2),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'hermes':
        return Colors.purple;
      case 'firebase_ai':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatProviderName(String provider) {
    switch (provider.toLowerCase()) {
      case 'hermes':
        return 'Hermes Agent';
      case 'firebase_ai':
        return 'Firebase AI';
      default:
        return provider;
    }
  }
}

/// Template effectiveness comparison
class _TemplateEffectivenessSection extends ConsumerWidget {
  const _TemplateEffectivenessSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(templateRatingStatsProvider(limitDays: 30));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prompt Template Effectiveness',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) {
            if (stats.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No template ratings yet')),
                ),
              );
            }

            // Group by template and calculate average
            final templateMap = <String, List<dynamic>>{};
            for (final stat in stats) {
              templateMap.putIfAbsent(stat.templateName, () => []).add(stat);
            }

            final templateAverages =
                templateMap.entries.map((entry) {
                  final stats = entry.value;
                  final avgRating =
                      stats.map((s) => s.avgRating).reduce((a, b) => a + b) /
                      stats.length;
                  final totalRatings = stats
                      .map((s) => s.ratedConversations)
                      .reduce((a, b) => a + b);
                  return MapEntry(entry.key, {
                    'avg': avgRating,
                    'count': totalRatings,
                  });
                }).toList()..sort(
                  (a, b) => (b.value['avg'] as double).compareTo(
                    a.value['avg'] as double,
                  ),
                );

            return Column(
              children: templateAverages.take(5).map((entry) {
                final templateName = entry.key;
                final avgRating = entry.value['avg'] as double;
                final count = entry.value['count'] as int;

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      CupertinoIcons.doc_text,
                      color: Colors.blue,
                    ),
                    title: Text(templateName),
                    subtitle: Text('$count ratings'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.star_fill,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          avgRating.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Template usage statistics
class _TemplateUsageSection extends ConsumerWidget {
  const _TemplateUsageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(templateUsageStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Used Templates',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) {
            if (stats.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No templates used yet')),
                ),
              );
            }

            // Filter and group by template
            final templateMap = <String, int>{};
            for (final stat in stats) {
              templateMap[stat.templateName] =
                  (templateMap[stat.templateName] ?? 0) +
                  stat.conversationCount;
            }

            final sortedTemplates = templateMap.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Column(
              children: sortedTemplates.take(5).map((entry) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(entry.value.toString())),
                    title: Text(entry.key),
                    subtitle: Text('${entry.value} conversations'),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}
