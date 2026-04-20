import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agent_template/core/constants/api_constants.dart';

final _log = Logger('HermesService');

/// Service for communicating with the Hermes AI Agent via Supabase Edge Function
class HermesService {
  final SupabaseClient _supabase;

  HermesService(this._supabase);

  /// Send a chat completion request to Hermes
  ///
  /// [messages] - List of chat messages in OpenAI format
  /// [model] - Optional model name (defaults to gemini-3-flash-preview)
  /// [stream] - Whether to stream the response (defaults to false)
  ///
  /// Returns the response from Hermes in OpenAI-compatible format
  Future<Map<String, dynamic>> sendChatCompletion({
    required List<Map<String, String>> messages,
    String? model,
    bool stream = false,
  }) async {
    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;

    _log.info('Current user: ${user?.id ?? "null"}');
    _log.info('Current session: ${session != null ? "exists" : "null"}');
    _log.info('Access token length: ${session?.accessToken.length ?? 0}');
    if (session?.accessToken != null) {
      _log.info(
        'Access token (first 30): ${session!.accessToken.substring(0, 30)}...',
      );
    }

    if (session == null) {
      throw Exception('User not authenticated');
    }

    _log.info('Sending chat completion via direct HTTP call');
    _log.info('Message count: ${messages.length}');

    final requestBody = {
      'messages': messages,
      if (model != null) 'model': model,
      'stream': stream,
    };

    try {
      // Use Supabase Edge Function (deployed with --no-verify-jwt to support ES256)
      final url = Uri.parse(ApiConstants.hermesProxyUrl);

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': ApiConstants.supabaseAnonKey,
      };

      _log.info('Request URL: $url');
      _log.info('Headers set: ${headers.keys.join(", ")}');

      final httpResponse = await http.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      _log.info('Response status: ${httpResponse.statusCode}');

      if (httpResponse.statusCode == 200) {
        return json.decode(httpResponse.body) as Map<String, dynamic>;
      } else if (httpResponse.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (httpResponse.statusCode == 403) {
        final data = json.decode(httpResponse.body) as Map<String, dynamic>;
        final message = data['message'] ?? 'Subscription required';
        throw Exception(message);
      } else {
        final data = json.decode(httpResponse.body) as Map<String, dynamic>;
        final error = data['error'] ?? 'Unknown error';
        final message = data['message'] ?? '';
        throw Exception('$error: $message');
      }
    } catch (e) {
      _log.severe('Error sending chat completion: $e');
      rethrow;
    }
  }

  /// Extract the assistant's message content from the response
  String extractMessageContent(Map<String, dynamic> response) {
    try {
      final choices = response['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('No choices in response');
      }

      final firstChoice = choices[0] as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>;
      final content = message['content'] as String;

      return content;
    } catch (e) {
      _log.severe('Error extracting message content: $e');
      throw Exception('Invalid response format from Hermes');
    }
  }
}
