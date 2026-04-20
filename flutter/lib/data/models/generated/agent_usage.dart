// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: agent_usage

class AgentUsage {
  final String id;
  final String userId;
  final String model;
  final int? messageCount;
  final int? tokensUsed;
  final DateTime timestamp;

  const AgentUsage({
    required this.id,
    required this.userId,
    required this.model,
    this.messageCount,
    this.tokensUsed,
    required this.timestamp,
  });

  factory AgentUsage.fromJson(Map<String, dynamic> json) => AgentUsage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      model: json['model'] as String,
      messageCount: json['message_count'] as int?,
      tokensUsed: json['tokens_used'] as int?,
      timestamp: DateTime.parse(json['timestamp']),
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'model': model,
      'message_count': messageCount,
      'tokens_used': tokensUsed,
      'timestamp': timestamp.toIso8601String(),
      };

  AgentUsage copyWith({
    String? id,
    String? userId,
    String? model,
    int? messageCount,
    int? tokensUsed,
    DateTime? timestamp,
  }) => AgentUsage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      model: model ?? this.model,
      messageCount: messageCount ?? this.messageCount,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      timestamp: timestamp ?? this.timestamp,
      );
}
