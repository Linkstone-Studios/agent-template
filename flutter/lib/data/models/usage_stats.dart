/// Data model for aggregated AI usage statistics
/// This is a computed model (not from database) that summarizes usage data
class UsageStats {
  final int totalCalls;
  final int totalInputTokens;
  final int totalOutputTokens;
  final double totalCost;
  final int hermesUsage;
  final int firebaseAiUsage;

  const UsageStats({
    required this.totalCalls,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCost,
    required this.hermesUsage,
    required this.firebaseAiUsage,
  });

  UsageStats copyWith({
    int? totalCalls,
    int? totalInputTokens,
    int? totalOutputTokens,
    double? totalCost,
    int? hermesUsage,
    int? firebaseAiUsage,
  }) {
    return UsageStats(
      totalCalls: totalCalls ?? this.totalCalls,
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
      totalCost: totalCost ?? this.totalCost,
      hermesUsage: hermesUsage ?? this.hermesUsage,
      firebaseAiUsage: firebaseAiUsage ?? this.firebaseAiUsage,
    );
  }

  @override
  String toString() {
    return 'UsageStats(totalCalls: $totalCalls, inputTokens: $totalInputTokens, '
        'outputTokens: $totalOutputTokens, totalCost: \$$totalCost)';
  }
}

