# Chat Tools

This directory contains tool implementations for AI chat providers.

Tools extend the capabilities of AI models by allowing them to execute functions like web search, calculations, API calls, etc.

## Adding New Tools

1. Create a new file in this directory (e.g., `my_tool.dart`)
2. Extend `BaseTool` class
3. Register the tool in your AI provider

## Example

```dart
class WebSearchTool extends BaseTool {
  // Implement your tool here
}
```

Replace this with your project's actual tool implementations.