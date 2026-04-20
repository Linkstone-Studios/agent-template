// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: tool_executions

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

class ToolExecutions {
  final String id;
  final String userId;
  final String? sessionId;
  final String toolName;
  final String category;
  final String argsHash;
  final int executionTimeMs;
  final bool success;
  final String? errorMessage;
  final bool cached;
  final AiProvider provider;
  final DateTime createdAt;

  const ToolExecutions({
    required this.id,
    required this.userId,
    this.sessionId,
    required this.toolName,
    required this.category,
    required this.argsHash,
    required this.executionTimeMs,
    required this.success,
    this.errorMessage,
    required this.cached,
    required this.provider,
    required this.createdAt,
  });

  factory ToolExecutions.fromJson(Map<String, dynamic> json) => ToolExecutions(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sessionId: json['session_id'] as String?,
      toolName: json['tool_name'] as String,
      category: json['category'] as String,
      argsHash: json['args_hash'] as String,
      executionTimeMs: json['execution_time_ms'] as int,
      success: json['success'] as bool,
      errorMessage: json['error_message'] as String?,
      cached: json['cached'] as bool,
      provider: AiProvider.fromString(json['provider'])!,
      createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'tool_name': toolName,
      'category': category,
      'args_hash': argsHash,
      'execution_time_ms': executionTimeMs,
      'success': success,
      'error_message': errorMessage,
      'cached': cached,
      'provider': provider.value,
      'created_at': createdAt.toIso8601String(),
      };

  ToolExecutions copyWith({
    String? id,
    String? userId,
    String? sessionId,
    String? toolName,
    String? category,
    String? argsHash,
    int? executionTimeMs,
    bool? success,
    String? errorMessage,
    bool? cached,
    AiProvider? provider,
    DateTime? createdAt,
  }) => ToolExecutions(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      toolName: toolName ?? this.toolName,
      category: category ?? this.category,
      argsHash: argsHash ?? this.argsHash,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      cached: cached ?? this.cached,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      );
}
