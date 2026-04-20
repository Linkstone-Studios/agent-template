import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/supabase_provider.dart';

part 'prompt_template_repository.g.dart';

/// Repository for managing prompt templates
/// Provides type-safe access to the prompt_templates table
///
/// Prompt templates enable systematic testing of different AI configurations
/// for AI tasks. Teams can create reusable prompts for:
/// - Question generation
/// - Item critique
/// - Psychometric analysis
/// - Content review
@riverpod
PromptTemplateRepository promptTemplateRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return PromptTemplateRepository(client);
}

class PromptTemplateRepository {
  final SupabaseClient _client;

  PromptTemplateRepository(this._client);

  /// Get all templates (user's + public)
  ///
  /// Returns templates owned by the current user plus any public templates
  /// shared across the team.
  Future<List<PromptTemplates>> getTemplates() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('prompt_templates')
        .select()
        .or('user_id.eq.$userId,is_public.eq.true')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => PromptTemplates.fromJson(json))
        .toList();
  }

  /// Get default template for current user
  ///
  /// Returns the user's default template if one is set, null otherwise.
  Future<PromptTemplates?> getDefaultTemplate() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('prompt_templates')
        .select()
        .eq('user_id', userId)
        .eq('is_default', true)
        .maybeSingle();

    if (response == null) return null;
    return PromptTemplates.fromJson(response);
  }

  /// Create a new template
  ///
  /// If isDefault is true, this will automatically unset any existing default
  /// template (enforced by database unique constraint).
  Future<PromptTemplates> createTemplate({
    required String name,
    required String systemPrompt,
    String? description,
    bool isDefault = false,
    bool isPublic = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.from('prompt_templates').insert({
      'user_id': userId,
      'name': name,
      'system_prompt': systemPrompt,
      'description': description,
      'is_default': isDefault,
      'is_public': isPublic,
    }).select().single();

    return PromptTemplates.fromJson(response);
  }

  /// Update a template
  ///
  /// Only updates non-null fields. updated_at is automatically set by the database.
  Future<PromptTemplates> updateTemplate({
    required String id,
    String? name,
    String? systemPrompt,
    String? description,
    bool? isDefault,
    bool? isPublic,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (systemPrompt != null) updates['system_prompt'] = systemPrompt;
    if (description != null) updates['description'] = description;
    if (isDefault != null) updates['is_default'] = isDefault;
    if (isPublic != null) updates['is_public'] = isPublic;
    updates['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('prompt_templates')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return PromptTemplates.fromJson(response);
  }

  /// Delete a template
  Future<void> deleteTemplate(String id) async {
    await _client.from('prompt_templates').delete().eq('id', id);
  }

  /// Set a template as the default
  ///
  /// This unsets any existing default template and sets the specified one as default.
  Future<void> setAsDefault(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Unset current default
    await _client
        .from('prompt_templates')
        .update({'is_default': false})
        .eq('user_id', userId)
        .eq('is_default', true);

    // Set new default
    await _client
        .from('prompt_templates')
        .update({'is_default': true})
        .eq('id', id);
  }
}

