// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: prompt_templates

class PromptTemplates {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String systemPrompt;
  final bool isDefault;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PromptTemplates({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.systemPrompt,
    required this.isDefault,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PromptTemplates.fromJson(Map<String, dynamic> json) => PromptTemplates(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      systemPrompt: json['system_prompt'] as String,
      isDefault: json['is_default'] as bool,
      isPublic: json['is_public'] as bool,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'system_prompt': systemPrompt,
      'is_default': isDefault,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      };

  PromptTemplates copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? systemPrompt,
    bool? isDefault,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PromptTemplates(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isDefault: isDefault ?? this.isDefault,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      );
}
