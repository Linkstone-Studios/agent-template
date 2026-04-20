// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: ai_performance_metrics

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

class AiPerformanceMetrics {
  final String id;
  final String? userId;
  final AiProvider provider;
  final String model;
  final int latencyMs;
  final int inputTokens;
  final int outputTokens;
  final bool usedTools;
  final DateTime createdAt;

  const AiPerformanceMetrics({
    required this.id,
    this.userId,
    required this.provider,
    required this.model,
    required this.latencyMs,
    required this.inputTokens,
    required this.outputTokens,
    required this.usedTools,
    required this.createdAt,
  });

  factory AiPerformanceMetrics.fromJson(Map<String, dynamic> json) => AiPerformanceMetrics(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      provider: AiProvider.fromString(json['provider'])!,
      model: json['model'] as String,
      latencyMs: json['latency_ms'] as int,
      inputTokens: json['input_tokens'] as int,
      outputTokens: json['output_tokens'] as int,
      usedTools: json['used_tools'] as bool,
      createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'provider': provider.value,
      'model': model,
      'latency_ms': latencyMs,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'used_tools': usedTools,
      'created_at': createdAt.toIso8601String(),
      };

  AiPerformanceMetrics copyWith({
    String? id,
    String? userId,
    AiProvider? provider,
    String? model,
    int? latencyMs,
    int? inputTokens,
    int? outputTokens,
    bool? usedTools,
    DateTime? createdAt,
  }) => AiPerformanceMetrics(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      latencyMs: latencyMs ?? this.latencyMs,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      usedTools: usedTools ?? this.usedTools,
      createdAt: createdAt ?? this.createdAt,
      );
}
