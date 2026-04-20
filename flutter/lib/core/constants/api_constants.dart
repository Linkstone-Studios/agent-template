import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API constants for Supabase and other services
class ApiConstants {
  ApiConstants._();

  static String get supabaseUrl {
    // For web builds, prioritize compile-time values (from --dart-define)
    if (kIsWeb) {
      const compileTimeValue = String.fromEnvironment('SUPABASE_URL');
      if (compileTimeValue.isNotEmpty) return compileTimeValue;
    }

    // For mobile/desktop, use .env file
    final envValue = dotenv.env['SUPABASE_URL'];
    if (envValue != null && envValue.isNotEmpty) return envValue;

    // Fallback to compile-time value if .env didn't work
    const compileTimeValue = String.fromEnvironment('SUPABASE_URL');
    if (compileTimeValue.isNotEmpty) return compileTimeValue;

    return 'https://placeholder.supabase.co';
  }

  static String get supabaseAnonKey {
    // For web builds, prioritize compile-time values (from --dart-define)
    if (kIsWeb) {
      const compileTimeValue = String.fromEnvironment('SUPABASE_ANON_KEY');
      if (compileTimeValue.isNotEmpty) return compileTimeValue;
    }

    // For mobile/desktop, use .env file
    final envValue = dotenv.env['SUPABASE_ANON_KEY'];
    if (envValue != null && envValue.isNotEmpty) return envValue;

    // Fallback to compile-time value if .env didn't work
    const compileTimeValue = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (compileTimeValue.isNotEmpty) return compileTimeValue;

    return 'placeholder-key';
  }

  /// Hermes AI Agent proxy endpoint URL
  /// This goes through the Supabase Edge Function for auth/subscription validation
  static String get hermesProxyUrl {
    // Construct the Supabase Functions URL
    final baseUrl = supabaseUrl;
    if (baseUrl == 'https://placeholder.supabase.co') {
      return 'https://placeholder.supabase.co/functions/v1/hermes-proxy';
    }
    return '$baseUrl/functions/v1/hermes-proxy';
  }
}
