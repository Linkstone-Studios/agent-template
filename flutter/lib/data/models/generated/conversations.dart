// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: conversations

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

class Conversations {
  final String id;
  final String userId;
  final String? title;
  final AiProvider provider;
  final String model;
  final String? promptTemplateId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final bool isArchived;

  const Conversations({
    required this.id,
    required this.userId,
    this.title,
    required this.provider,
    required this.model,
    this.promptTemplateId,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.isArchived,
  });

  factory Conversations.fromJson(Map<String, dynamic> json) => Conversations(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      provider: AiProvider.fromString(json['provider'])!,
      model: json['model'] as String,
      promptTemplateId: json['prompt_template_id'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: json['message_count'] as int,
      isArchived: json['is_archived'] as bool,
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'title': title,
      'provider': provider.value,
      'model': model,
      'prompt_template_id': promptTemplateId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'message_count': messageCount,
      'is_archived': isArchived,
      };

  Conversations copyWith({
    String? id,
    String? userId,
    String? title,
    AiProvider? provider,
    String? model,
    String? promptTemplateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    bool? isArchived,
  }) => Conversations(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      promptTemplateId: promptTemplateId ?? this.promptTemplateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      isArchived: isArchived ?? this.isArchived,
      );
}
