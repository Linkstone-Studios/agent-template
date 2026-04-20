import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agent_template/features/chat/tools/base_tool.dart';

/// Service for managing tool approval preferences
///
/// Tracks which tools the user has approved for auto-execution
/// and handles the approval flow logic.
class ToolApprovalService {
  static const String _prefixKey = 'tool_approval_';

  final SharedPreferences _prefs;

  ToolApprovalService(this._prefs);

  /// Check if a tool is auto-approved
  bool isAutoApproved(String toolName) {
    return _prefs.getBool('$_prefixKey$toolName') ?? false;
  }

  /// Set auto-approval for a tool
  Future<void> setAutoApproved(String toolName, bool approved) async {
    await _prefs.setBool('$_prefixKey$toolName', approved);
  }

  /// Clear auto-approval for a specific tool
  Future<void> clearApproval(String toolName) async {
    await _prefs.remove('$_prefixKey$toolName');
  }

  /// Clear all tool approvals
  Future<void> clearAllApprovals() async {
    final keys = _prefs.getKeys();
    final approvalKeys = keys.where((k) => k.startsWith(_prefixKey));
    for (final key in approvalKeys) {
      await _prefs.remove(key);
    }
  }

  /// Get all auto-approved tools
  List<String> getAutoApprovedTools() {
    final keys = _prefs.getKeys();
    final approvalKeys = keys.where((k) => k.startsWith(_prefixKey));
    return approvalKeys
        .where((k) => _prefs.getBool(k) == true)
        .map((k) => k.substring(_prefixKey.length))
        .toList();
  }

  /// Determine if a tool needs user approval
  /// 
  /// Returns false if:
  /// - Tool has requiresApproval = false
  /// - Tool is auto-approved by user
  /// 
  /// Returns true if:
  /// - Tool has requiresApproval = true AND not auto-approved
  bool needsApproval(AIChatTool tool) {
    // If tool doesn't require approval, no need to ask
    if (!tool.requiresApproval) {
      return false;
    }

    // Check if user has auto-approved this tool
    return !isAutoApproved(tool.name);
  }
}

/// Provider for ToolApprovalService
final toolApprovalServiceProvider = Provider<ToolApprovalService>((ref) {
  throw UnimplementedError('ToolApprovalService must be overridden');
});

/// Provider for initializing the tool approval service
final toolApprovalServiceInitProvider = FutureProvider<ToolApprovalService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return ToolApprovalService(prefs);
});

