import 'package:agent_template/core/constants/api_constants.dart';
import 'package:agent_template/core/services/analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseAIProvider extends AIChatProvider {
  final SupabaseClient _supabase;
  final String _model;
  final List<ChatMessage> _history = [];
  String? _systemPrompt;
  String? _conversationId;

  FirebaseAIProvider({
    required SupabaseClient supabase,
    String model = 'gemini-3-flash',
  }) : _supabase = supabase,
       _model = model;

  @override
  String get providerId => 'firebase_ai';

  @override
  String get providerName => 'Firebase AI';

  @override
  String? get model => _model;

  @override
  String? get systemPrompt => _systemPrompt;

  @override
  void updateSystemPrompt(String? prompt) {
    _systemPrompt = prompt;
    notifyListeners();
  }

  @override
  String? get conversationId => _conversationId;

  @override
  void setConversationId(String? id) {
    _conversationId = id;
  }

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
    supportsStreaming: true,
    supportsTools: true,
    supportsMultimodal: true,
    supportsVision: true,
    supportsAudio: false,
    maxTokens: 32768,
    supportedModels: ['gemini-3-flash', 'gemini-1.5-pro', 'gemini-2.0-flash'],
  );

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    _history.add(ChatMessage.user(prompt, attachments));
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session == null) throw Exception('User not authenticated');

      final messages = _history
        .where((msg) => msg.text != null && msg.text!.isNotEmpty)
        .map((msg) => {
          'role': msg.origin == MessageOrigin.user ? 'user' : 'model',
          'parts': [{'text': msg.text}],
        })
        .toList();

      if (_systemPrompt != null) {
        messages.insert(0, {
          'role': 'user',
          'parts': [{'text': _systemPrompt}],
        });
      }

      final response = await _supabase.functions.invoke(
        'firebase-ai-proxy',
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: {
          'messages': messages,
          'model': _model,
        },
      );

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error';
        throw Exception(error);
      }

      final buffer = StringBuffer();
      final stream = response.data as Stream<String>;

      await for (final chunk in stream) {
        buffer.write(chunk);
        yield chunk;
      }

      _history.add(ChatMessage(
        origin: MessageOrigin.llm,
        text: buffer.toString(),
        attachments: const [],
      ));
      notifyListeners();

    } catch (e) {
      final errorMsg = 'Error: ${e.toString()}';
      _history.add(ChatMessage(
        origin: MessageOrigin.llm,
        text: errorMsg,
        attachments: const [],
      ));
      notifyListeners();
      yield errorMsg;
    }
  }

  @override
  Future<ToolResult> executeTool(String toolName, Map<String, dynamic> args) async {
    return ToolResult(
      toolName: toolName,
      success: true,
      displayText: 'Tool executed',
      data: {},
    );
  }

  @override
  List<ToolDefinition> get availableTools => [];

  @override
  Map<String, dynamic> get metadata => {
    'provider': 'firebase_ai',
    'model': _model,
  };
}