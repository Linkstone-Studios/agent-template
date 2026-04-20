import 'package:flutter/foundation.dart';
import 'chat_attachment.dart';

/// Origin of a chat message
enum MessageOrigin { user, assistant, system }

/// Status of a message
enum MessageStatus { sending, sent, delivered, failed, streaming }

/// A chat message with rich metadata
@immutable
class ChatMessage {
  final String id;
  final MessageOrigin origin;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;
  final String? error;
  final List<ChatAttachment>? attachments;

  const ChatMessage({
    required this.id,
    required this.origin,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.metadata,
    this.error,
    this.attachments,
  });

  /// Create a user message
  factory ChatMessage.user(
    String text, {
    String? id,
    List<ChatAttachment>? attachments,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      origin: MessageOrigin.user,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      attachments: attachments,
    );
  }

  /// Create an assistant message
  factory ChatMessage.assistant(
    String text, {
    String? id,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      origin: MessageOrigin.assistant,
      text: text,
      timestamp: DateTime.now(),
      status: status ?? MessageStatus.sent,
    );
  }

  /// Create a system message
  factory ChatMessage.system(String text, {String? id}) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      origin: MessageOrigin.system,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  /// Copy with modifications
  ChatMessage copyWith({
    String? id,
    MessageOrigin? origin,
    String? text,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    String? error,
    List<ChatAttachment>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      error: error ?? this.error,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, origin: $origin, text: ${text.substring(0, text.length > 50 ? 50 : text.length)}..., timestamp: $timestamp, status: $status)';
  }
}

/// Request for clarification from the AI agent
@immutable
class ClarificationRequest {
  final String id;
  final String question;
  final List<String>? options;
  final bool allowCustomInput;
  final String? hint;

  const ClarificationRequest({
    required this.id,
    required this.question,
    this.options,
    this.allowCustomInput = true,
    this.hint,
  });
}

/// Response to a clarification request
@immutable
class ClarificationResponse {
  final String requestId;
  final String response;
  final bool isFromOptions;

  const ClarificationResponse({
    required this.requestId,
    required this.response,
    this.isFromOptions = false,
  });
}
