import 'package:flutter/widgets.dart';
import '../models/chat_message.dart';

/// Abstract interface for AI chat providers
/// Enables swapping between Hermes, Firebase AI, and future providers
///
/// This interface extends ChangeNotifier for UI reactivity
abstract class AIChatProvider with ChangeNotifier {
  /// Unique identifier for this provider (e.g., "hermes", "firebase_ai")
  String get providerId;

  /// Human-readable name for display in UI
  String get providerName;

  /// Capabilities this provider supports
  ProviderCapabilities get capabilities;

  /// Current model being used (e.g., "gemini-3-flash")
  String? get model;

  /// System prompt (nullable) - instructions that guide the AI behavior
  String? get systemPrompt;

  /// Update the system prompt for this provider
  void updateSystemPrompt(String? prompt);

  /// Current conversation ID for message persistence
  String? get conversationId;

  /// Set the conversation ID for this provider
  void setConversationId(String? id);

  /// Message history for this conversation
  List<ChatMessage> get history;

  /// Set message history (for restoring conversations)
  set history(List<ChatMessage> value);

  /// Send a message and get streaming response
  Stream<String> sendMessageStream(String prompt);

  /// Execute a tool/function call
  ///
  /// This method is called when the AI wants to use a tool (e.g., web search,
  /// calculator, weather lookup). The implementation should execute the tool
  /// and return the result.
  Future<ToolResult> executeTool(String toolName, Map<String, dynamic> args);

  /// Get list of available tools/functions for this provider
  List<ToolDefinition> get availableTools;

  /// Provider-specific metadata for analytics and debugging
  Map<String, dynamic> get metadata;
}

/// Capabilities that a provider may support
///
/// This allows the UI to adapt based on what the provider can do
class ProviderCapabilities {
  /// Whether this provider supports streaming responses
  final bool supportsStreaming;

  /// Whether this provider supports tool/function calling
  final bool supportsTools;

  /// Whether this provider supports multimodal inputs (text + images)
  final bool supportsMultimodal;

  /// Whether this provider supports vision/image understanding
  final bool supportsVision;

  /// Whether this provider supports audio inputs
  final bool supportsAudio;

  /// Maximum number of tokens this provider supports
  final int maxTokens;

  /// List of model names this provider supports
  final List<String> supportedModels;

  const ProviderCapabilities({
    this.supportsStreaming = false,
    this.supportsTools = false,
    this.supportsMultimodal = false,
    this.supportsVision = false,
    this.supportsAudio = false,
    this.maxTokens = 4096,
    this.supportedModels = const [],
  });

  /// Copy with method for creating modified capabilities
  ProviderCapabilities copyWith({
    bool? supportsStreaming,
    bool? supportsTools,
    bool? supportsMultimodal,
    bool? supportsVision,
    bool? supportsAudio,
    int? maxTokens,
    List<String>? supportedModels,
  }) {
    return ProviderCapabilities(
      supportsStreaming: supportsStreaming ?? this.supportsStreaming,
      supportsTools: supportsTools ?? this.supportsTools,
      supportsMultimodal: supportsMultimodal ?? this.supportsMultimodal,
      supportsVision: supportsVision ?? this.supportsVision,
      supportsAudio: supportsAudio ?? this.supportsAudio,
      maxTokens: maxTokens ?? this.maxTokens,
      supportedModels: supportedModels ?? this.supportedModels,
    );
  }
}

/// Definition of a tool/function that can be called by the AI
class ToolDefinition {
  /// Name of the tool (e.g., "web_search", "calculator")
  final String name;

  /// Human-readable description of what the tool does
  final String description;

  /// JSON schema defining the parameters this tool accepts
  final Map<String, dynamic> parameters;

  const ToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'parameters': parameters};
  }
}

/// Result of executing a tool/function
class ToolResult {
  /// Name of the tool that was executed
  final String toolName;

  /// Whether the tool execution was successful
  final bool success;

  /// Human-readable text to display to the user
  final String displayText;

  /// Structured data returned by the tool
  final Map<String, dynamic> data;

  /// Error message if the tool execution failed
  final String? error;

  const ToolResult({
    required this.toolName,
    required this.success,
    required this.displayText,
    required this.data,
    this.error,
  });

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'tool_name': toolName,
      'success': success,
      'display_text': displayText,
      'data': data,
      if (error != null) 'error': error,
    };
  }
}
