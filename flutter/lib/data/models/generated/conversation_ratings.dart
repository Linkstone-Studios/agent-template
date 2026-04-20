// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: conversation_ratings

class ConversationRatings {
  final String id;
  final String conversationId;
  final String userId;
  final int rating;
  final String? notes;
  final DateTime createdAt;

  const ConversationRatings({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.rating,
    this.notes,
    required this.createdAt,
  });

  factory ConversationRatings.fromJson(Map<String, dynamic> json) => ConversationRatings(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'rating': rating,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      };

  ConversationRatings copyWith({
    String? id,
    String? conversationId,
    String? userId,
    int? rating,
    String? notes,
    DateTime? createdAt,
  }) => ConversationRatings(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      );
}
