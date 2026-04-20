import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agent_template/core/services/analytics_service.dart';
import '../models/chat_message.dart';
import '../services/hermes_service.dart';
import '../tools/base_tool.dart';
import '../tools/psychometric_calculator_tool.dart';
import 'ai_chat_provider.dart';

final _log = Logger('HermesProvider');

/// Hermes AI Provider - Connects to Hermes Agent via Supabase Edge Function
///
/// This provider implements the AIChatProvider interface for the Hermes Agent,
/// which runs on DigitalOcean and uses Google AI Studio API.
///
/// Key features:
/// - Multi-turn conversation support
/// - OpenAI-compatible API
/// - Simulated streaming for better UX
/// - Future: LangGraph-powered agentic workflows
/// - Performance analytics tracking
class HermesProvider extends AIChatProvider {
  final HermesService _hermesService;
  final AnalyticsService? _analyticsService;
  final String? _model;
  final List<ChatMessage> _history = [];
  String? _systemPrompt;
  String? _conversationId;
  late final ToolRegistry _toolRegistry;

  HermesProvider({
    required SupabaseClient supabase,
    String? model,
    AnalyticsService? analyticsService,
  }) : _hermesService = HermesService(supabase),
       _model = model,
       _analyticsService = analyticsService {
    // Initialize tool registry with tools
    _toolRegistry = ToolRegistry();
    _toolRegistry.register(PsychometricCalculatorTool());
  }

  @override
  List<ChatMessage> get history => _history;

  @override
  set history(List<ChatMessage> value) {
    _history.clear();
    _history.addAll(value);
    notifyListeners();
  }

  Stream<String> generateStream(String prompt) async* {
    _log.info(
      'Generating response (no history) for prompt: ${prompt.length > 50 ? prompt.substring(0, 50) : prompt}...',
    );

    try {
      // Convert the prompt to OpenAI message format
      final messages = [
        {'role': 'user', 'content': prompt},
      ];

      final response = await _hermesService.sendChatCompletion(
        messages: messages,
        model: model,
        stream: false,
      );

      final content = _hermesService.extractMessageContent(response);

      // Emit the response as text chunks to simulate streaming
      final words = content.split(' ');
      for (var i = 0; i < words.length; i++) {
        final word = words[i];
        final isLast = i == words.length - 1;

        yield isLast ? word : '$word ';

        // Small delay to simulate streaming
        await Future.delayed(const Duration(milliseconds: 20));
      }
    } catch (e) {
      _log.severe('Error generating response: $e');
      yield 'Error: ${e.toString()}';
    }
  }

  @override
  Stream<String> sendMessageStream(String prompt) async* {
    _log.info(
      'Sending message with history for prompt: ${prompt.length > 50 ? prompt.substring(0, 50) : prompt}...',
    );
    _log.info('Stream started - about to add messages to history');

    // Track start time for performance metrics
    final startTime = DateTime.now();
    int inputTokens = 0;
    int outputTokens = 0;

    try {
      // Add user message to history
      _history.add(ChatMessage.user(prompt));
      _log.info(
        'Added user message to history. History count: ${_history.length}',
      );

      // Add empty assistant message as placeholder for streaming state
      _history.add(ChatMessage.assistant('', status: MessageStatus.streaming));
      _log.info('Added empty placeholder. History count: ${_history.length}');
      notifyListeners();
      _log.info('Called notifyListeners() after adding empty placeholder');

      // Convert entire history to OpenAI message format
      // IMPORTANT: Filter out empty messages (like the loading placeholder)
      // The API requires the last message to be from the user
      final messages = _history.where((msg) => msg.text.trim().isNotEmpty).map((
        msg,
      ) {
        final role = msg.origin == MessageOrigin.user ? 'user' : 'assistant';
        return {'role': role, 'content': msg.text};
      }).toList();

      _log.info(
        'Converted history to API format. Message count: ${messages.length}',
      );

      // Estimate input tokens (rough approximation: 1 token ≈ 4 characters)
      inputTokens = messages
          .map((m) => (m['content'] as String).length ~/ 4)
          .fold(0, (sum, tokens) => sum + tokens);

      _log.info('Calling Hermes service...');
      final response = await _hermesService.sendChatCompletion(
        messages: messages,
        model: model,
        stream: false,
      );

      final content = _hermesService.extractMessageContent(response);
      _log.info('Got response content. Length: ${content.length} characters');

      // Estimate output tokens
      outputTokens = content.length ~/ 4;

      // Emit response as text chunks and update placeholder message in real-time
      final words = content.split(' ');
      final buffer = StringBuffer();

      _log.info('About to yield ${words.length} word chunks');
      for (var i = 0; i < words.length; i++) {
        final word = words[i];
        final isLast = i == words.length - 1;
        final chunk = isLast ? word : '$word ';

        buffer.write(chunk);

        // Update the placeholder message with accumulated text
        // This allows the UI to display the streaming response in real-time
        if (_history.isNotEmpty &&
            _history.last.origin == MessageOrigin.assistant) {
          _history[_history.length - 1] = ChatMessage.assistant(
            buffer.toString(),
            id: _history.last.id,
            status: MessageStatus.streaming,
          );

          // Notify listeners every 5 words to avoid excessive rebuilds
          if (i % 5 == 0 || isLast) {
            notifyListeners();
          }
        }

        _log.fine('Yielding chunk $i: "$chunk"');
        yield chunk;

        // Small delay to simulate streaming
        await Future.delayed(const Duration(milliseconds: 20));
      }

      _log.info(
        'Finished yielding all chunks. Final history count: ${_history.length}',
      );

      // Mark message as sent (streaming complete)
      if (_history.isNotEmpty &&
          _history.last.origin == MessageOrigin.assistant) {
        _history[_history.length - 1] = ChatMessage.assistant(
          buffer.toString(),
          id: _history.last.id,
          status: MessageStatus.sent,
        );
      }

      // Final notification to ensure UI is up to date
      notifyListeners();
      _log.info('Called final notifyListeners() after streaming complete');

      // Track analytics - successful response
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      await _analyticsService?.logResponseReceived(
        provider: providerId,
        model: model ?? 'gemini-3-flash-preview',
        responseTimeMs: responseTime,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        usedTools: false, // TODO: Track actual tool usage
      );
    } catch (e) {
      _log.severe('Error sending message: $e');
      final errorMsg = 'Error: ${e.toString()}';

      // Track analytics - error
      await _analyticsService?.logError(
        provider: providerId,
        errorType: e.runtimeType.toString(),
        errorMessage: e.toString(),
      );

      // Remove the placeholder message if it exists
      if (_history.isNotEmpty &&
          _history.last.origin == MessageOrigin.assistant &&
          _history.last.text.trim().isEmpty) {
        _history.removeLast();
      }

      _history.add(
        ChatMessage.assistant(errorMsg, status: MessageStatus.failed),
      );
      notifyListeners();
      yield errorMsg;
    }
  }

  // ========================================================================
  // AIChatProvider Interface Implementation
  // ========================================================================

  @override
  String get providerId => 'hermes';

  @override
  String get providerName => 'Hermes Agent';

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
    supportsStreaming: true, // Simulated streaming
    supportsTools: true, // Tool calling now enabled
    supportsMultimodal: false,
    supportsVision: false,
    supportsAudio: false,
    maxTokens: 32768, // Gemini 3 Flash context window
    supportedModels: ['gemini-3-flash-preview', 'gemini-2.0-flash-exp'],
  );

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
    notifyListeners();
  }

  @override
  Future<ToolResult> executeTool(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    _log.info('Executing tool: $toolName with args: $args');

    final startTime = DateTime.now();
    try {
      final result = await _toolRegistry.executeTool(toolName, args);

      // Track successful tool execution
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;
      await _analyticsService?.logToolCall(
        provider: providerId,
        toolName: toolName,
        success: result.success,
        executionTimeMs: executionTime,
      );

      return result;
    } catch (e) {
      _log.severe('Tool execution failed: $e');

      // Track failed tool execution
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;
      await _analyticsService?.logToolCall(
        provider: providerId,
        toolName: toolName,
        success: false,
        executionTimeMs: executionTime,
      );

      return ToolResult(
        toolName: toolName,
        success: false,
        displayText: 'Tool execution failed: ${e.toString()}',
        data: {},
        error: e.toString(),
      );
    }
  }

  @override
  List<ToolDefinition> get availableTools => _toolRegistry.getToolDefinitions();

  @override
  Map<String, dynamic> get metadata => {
    'provider': 'hermes',
    'model': _model ?? 'gemini-3-flash-preview',
    'deployment': 'digitalocean',
    'api_type': 'openai_compatible',
    'conversation_id': _conversationId,
    'message_count': _history.length,
  };
}
