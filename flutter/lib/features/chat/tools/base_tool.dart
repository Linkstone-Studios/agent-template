import 'package:agent_template/features/chat/providers/ai_chat_provider.dart';

/// Base interface for all AI tools/functions
///
/// Tools are executable functions that AI providers can call to enhance their
/// capabilities (e.g., web search, calculations, API calls, etc.)
abstract class AIChatTool {
  /// Unique identifier for this tool
  String get name;

  /// Human-readable description of what this tool does
  /// This is shown to the AI model to help it decide when to use the tool
  String get description;

  /// JSON schema defining the parameters this tool accepts
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'type': 'object',
  ///   'properties': {
  ///     'query': {
  ///       'type': 'string',
  ///       'description': 'The search query'
  ///     }
  ///   },
  ///   'required': ['query']
  /// }
  /// ```
  Map<String, dynamic> get parameters;

  /// Whether this tool requires user approval before execution
  ///
  /// Auto-approved tools (false): calculator, web search, weather, read-only operations
  /// Requires approval (true): file writes, emails, database mutations, external APIs with cost
  bool get requiresApproval => false;

  /// Category for grouping tools in UI and approval dialogs
  /// Examples: 'computation', 'search', 'communication', 'file_system', 'database'
  String get category => 'general';

  /// Estimated cost category for this tool execution
  /// Used to help users understand resource usage
  ToolCostLevel get costLevel => ToolCostLevel.free;

  /// Execute the tool with the given arguments
  ///
  /// Returns a [ToolResult] containing:
  /// - success: Whether the tool executed successfully
  /// - displayText: Human-readable result to show to the user
  /// - data: Structured data that can be used by the AI
  /// - error: Error message if the tool failed
  Future<ToolResult> execute(Map<String, dynamic> args);

  /// Convert tool definition to the format expected by AI APIs
  /// (OpenAI function calling format)
  ToolDefinition toDefinition() {
    return ToolDefinition(
      name: name,
      description: description,
      parameters: parameters,
    );
  }

  /// Validate that the provided arguments match the expected schema
  ///
  /// This is a basic validation that checks required fields are present.
  /// Override this method for more complex validation logic.
  bool validateArgs(Map<String, dynamic> args) {
    final requiredFields = (parameters['required'] as List<dynamic>?) ?? [];

    for (final field in requiredFields) {
      if (!args.containsKey(field) || args[field] == null) {
        return false;
      }
    }

    return true;
  }

  /// Helper method to create a success result
  ToolResult success({
    required String displayText,
    Map<String, dynamic> data = const {},
  }) {
    return ToolResult(
      toolName: name,
      success: true,
      displayText: displayText,
      data: data,
    );
  }

  /// Helper method to create an error result
  ToolResult error(String message) {
    return ToolResult(
      toolName: name,
      success: false,
      displayText: 'Error: $message',
      data: {},
      error: message,
    );
  }
}

/// Registry for managing available tools
class ToolRegistry {
  final Map<String, AIChatTool> _tools = {};

  /// Register a tool
  void register(AIChatTool tool) {
    _tools[tool.name] = tool;
  }

  /// Unregister a tool
  void unregister(String name) {
    _tools.remove(name);
  }

  /// Get a tool by name
  AIChatTool? getTool(String name) {
    return _tools[name];
  }

  /// Get all registered tools
  List<AIChatTool> getAllTools() {
    return _tools.values.toList();
  }

  /// Get tool definitions for AI API calls
  List<ToolDefinition> getToolDefinitions() {
    return _tools.values.map((tool) => tool.toDefinition()).toList();
  }

  /// Execute a tool by name
  ///
  /// This is the legacy method without caching support.
  /// Prefer using `executeToolWithCache` for better performance.
  Future<ToolResult> executeTool(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];

    if (tool == null) {
      return ToolResult(
        toolName: name,
        success: false,
        displayText: 'Tool not found: $name',
        data: {},
        error: 'Tool not found',
      );
    }

    if (!tool.validateArgs(args)) {
      return tool.error('Invalid arguments provided');
    }

    try {
      return await tool.execute(args);
    } catch (e) {
      return tool.error('Execution failed: ${e.toString()}');
    }
  }

  /// Execute a tool with caching support
  ///
  /// Parameters:
  /// - name: Tool name
  /// - args: Tool arguments
  /// - cache: Optional cache service for storing/retrieving results
  /// - forceRefresh: If true, bypass cache and always execute
  ///
  /// Returns the cached result if available and valid, otherwise executes
  /// the tool and caches the result.
  Future<ToolResult> executeToolWithCache(
    String name,
    Map<String, dynamic> args, {
    dynamic cache, // ToolCacheService (dynamic to avoid circular dependency)
    bool forceRefresh = false,
  }) async {
    final tool = _tools[name];

    if (tool == null) {
      return ToolResult(
        toolName: name,
        success: false,
        displayText: 'Tool not found: $name',
        data: {},
        error: 'Tool not found',
      );
    }

    // Check cache if available and not forcing refresh
    if (cache != null && !forceRefresh) {
      try {
        // Use dynamic call to avoid import cycle
        final cachedResult = (cache as dynamic).get(name, args, tool.category);
        if (cachedResult != null) {
          return cachedResult as ToolResult;
        }
      } catch (e) {
        // Ignore cache errors, fall through to execution
      }
    }

    // Validate and execute
    if (!tool.validateArgs(args)) {
      return tool.error('Invalid arguments provided');
    }

    try {
      final result = await tool.execute(args);

      // Cache successful results
      if (cache != null && result.success) {
        try {
          (cache as dynamic).put(name, args, result, tool.category);
        } catch (e) {
          // Ignore cache errors
        }
      }

      return result;
    } catch (e) {
      return tool.error('Execution failed: ${e.toString()}');
    }
  }

  /// Clear all registered tools
  void clear() {
    _tools.clear();
  }
}

/// Cost level for tool execution
/// Used to inform users about resource usage
enum ToolCostLevel {
  /// No cost - completely free to execute (e.g., calculator, local operations)
  free,

  /// Low cost - minimal API calls or resources (e.g., weather lookup, basic search)
  low,

  /// Medium cost - moderate API usage (e.g., advanced search, image processing)
  medium,

  /// High cost - expensive operations (e.g., video processing, large data analysis)
  high,
}
