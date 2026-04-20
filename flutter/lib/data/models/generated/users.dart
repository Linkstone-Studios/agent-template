// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: users

class Users {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Users({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Users.fromJson(Map<String, dynamic> json) => Users(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      };

  Users copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Users(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      );
}
