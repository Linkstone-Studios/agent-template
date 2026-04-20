// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: chat_messages

enum MessageRole {
  user('user'),
  assistant('assistant'),
  system('system');

  const MessageRole(this.value);
  final String value;

  static MessageRole? fromString(String? value) {
    if (value == null) return null;
    try {
      return MessageRole.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

class ChatMessages {
  final String id;
  final String conversationId;
  final String userId;
  final MessageRole role;
  final String content;
  final String? metadata;
  final DateTime createdAt;

  const ChatMessages({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.content,
    this.metadata,
    required this.createdAt,
  });

  factory ChatMessages.fromJson(Map<String, dynamic> json) => ChatMessages(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: MessageRole.fromString(json['role'])!,
      content: json['content'] as String,
      metadata: json['metadata'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role.value,
      'content': content,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      };

  ChatMessages copyWith({
    String? id,
    String? conversationId,
    String? userId,
    MessageRole? role,
    String? content,
    String? metadata,
    DateTime? createdAt,
  }) => ChatMessages(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      );
}
