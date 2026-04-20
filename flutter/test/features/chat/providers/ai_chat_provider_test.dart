import 'package:flutter_test/flutter_test.dart';
import 'package:agent_template/features/chat/providers/ai_chat_provider.dart';

void main() {
  group('ProviderCapabilities', () {
    test('creates with default values', () {
      const capabilities = ProviderCapabilities();

      expect(capabilities.supportsStreaming, false);
      expect(capabilities.supportsTools, false);
      expect(capabilities.supportsMultimodal, false);
      expect(capabilities.supportsVision, false);
      expect(capabilities.supportsAudio, false);
      expect(capabilities.maxTokens, 4096);
      expect(capabilities.supportedModels, isEmpty);
    });

    test('creates with custom values', () {
      const capabilities = ProviderCapabilities(
        supportsStreaming: true,
        supportsTools: true,
        maxTokens: 8192,
        supportedModels: ['model-1', 'model-2'],
      );

      expect(capabilities.supportsStreaming, true);
      expect(capabilities.supportsTools, true);
      expect(capabilities.maxTokens, 8192);
      expect(capabilities.supportedModels, ['model-1', 'model-2']);
    });

    test('copyWith creates new instance with updated values', () {
      const original = ProviderCapabilities(
        supportsStreaming: false,
        maxTokens: 4096,
      );

      final updated = original.copyWith(
        supportsStreaming: true,
        maxTokens: 8192,
      );

      expect(updated.supportsStreaming, true);
      expect(updated.maxTokens, 8192);
      // Original should remain unchanged
      expect(original.supportsStreaming, false);
      expect(original.maxTokens, 4096);
    });
  });

  group('ToolDefinition', () {
    test('creates with required parameters', () {
      const tool = ToolDefinition(
        name: 'web_search',
        description: 'Search the web',
        parameters: {'query': 'string'},
      );

      expect(tool.name, 'web_search');
      expect(tool.description, 'Search the web');
      expect(tool.parameters, {'query': 'string'});
    });

    test('converts to JSON correctly', () {
      const tool = ToolDefinition(
        name: 'calculator',
        description: 'Perform calculations',
        parameters: {'expression': 'string'},
      );

      final json = tool.toJson();

      expect(json['name'], 'calculator');
      expect(json['description'], 'Perform calculations');
      expect(json['parameters'], {'expression': 'string'});
    });
  });

  group('ToolResult', () {
    test('creates with required parameters', () {
      const result = ToolResult(
        toolName: 'web_search',
        success: true,
        displayText: 'Found 10 results',
        data: {'count': 10},
      );

      expect(result.toolName, 'web_search');
      expect(result.success, true);
      expect(result.displayText, 'Found 10 results');
      expect(result.data, {'count': 10});
      expect(result.error, null);
    });

    test('creates with error', () {
      const result = ToolResult(
        toolName: 'calculator',
        success: false,
        displayText: 'Calculation failed',
        data: {},
        error: 'Invalid expression',
      );

      expect(result.success, false);
      expect(result.error, 'Invalid expression');
    });

    test('converts to JSON correctly', () {
      const result = ToolResult(
        toolName: 'web_search',
        success: true,
        displayText: 'Success',
        data: {'result': 'test'},
      );

      final json = result.toJson();

      expect(json['tool_name'], 'web_search');
      expect(json['success'], true);
      expect(json['display_text'], 'Success');
      expect(json['data'], {'result': 'test'});
      expect(json.containsKey('error'), false);
    });

    test('includes error in JSON when present', () {
      const result = ToolResult(
        toolName: 'test',
        success: false,
        displayText: 'Failed',
        data: {},
        error: 'Something went wrong',
      );

      final json = result.toJson();

      expect(json['error'], 'Something went wrong');
    });
  });
}

