// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: ai_usage_logs

enum AiProvider {
  hermes('hermes'),
  firebaseAi('firebase_ai');

  const AiProvider(this.value);
  final String value;

  static AiProvider? fromString(String? value) {
    if (value == null) return null;
    try {
      return AiProvider.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

class AiUsageLogs {
  final String id;
  final String userId;
  final AiProvider provider;
  final String model;
  final int? inputTokens;
  final int? outputTokens;
  final double? costUsd;
  final int? latencyMs;
  final DateTime createdAt;

  const AiUsageLogs({
    required this.id,
    required this.userId,
    required this.provider,
    required this.model,
    this.inputTokens,
    this.outputTokens,
    this.costUsd,
    this.latencyMs,
    required this.createdAt,
  });

  factory AiUsageLogs.fromJson(Map<String, dynamic> json) => AiUsageLogs(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: AiProvider.fromString(json['provider'])!,
      model: json['model'] as String,
      inputTokens: json['input_tokens'] as int?,
      outputTokens: json['output_tokens'] as int?,
      costUsd: json['cost_usd'] as double?,
      latencyMs: json['latency_ms'] as int?,
      createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'provider': provider.value,
      'model': model,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'cost_usd': costUsd,
      'latency_ms': latencyMs,
      'created_at': createdAt.toIso8601String(),
      };

  AiUsageLogs copyWith({
    String? id,
    String? userId,
    AiProvider? provider,
    String? model,
    int? inputTokens,
    int? outputTokens,
    double? costUsd,
    int? latencyMs,
    DateTime? createdAt,
  }) => AiUsageLogs(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      costUsd: costUsd ?? this.costUsd,
      latencyMs: latencyMs ?? this.latencyMs,
      createdAt: createdAt ?? this.createdAt,
      );
}
