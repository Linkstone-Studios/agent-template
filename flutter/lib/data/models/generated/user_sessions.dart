// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: user_sessions

enum AiProvider {
  hermes('hermes'),
  firebaseAi('firebase_ai');

  const AiProvider(this.value);
  final String value;

  static AiProvider? fromString(String? value) {
    if (value == null) return null;
    try {
      return AiProvider.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

enum Platform {
  web('web'),
  ios('ios'),
  android('android');

  const Platform(this.value);
  final String value;

  static Platform? fromString(String? value) {
    if (value == null) return null;
    try {
      return Platform.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

class UserSessions {
  final String id;
  final String? userId;
  final String appVersion;
  final AiProvider provider;
  final Platform platform;
  final DateTime sessionStart;
  final DateTime? sessionEnd;
  final int? messagesSent;
  final int? errorsCount;

  const UserSessions({
    required this.id,
    this.userId,
    required this.appVersion,
    required this.provider,
    required this.platform,
    required this.sessionStart,
    this.sessionEnd,
    this.messagesSent,
    this.errorsCount,
  });

  factory UserSessions.fromJson(Map<String, dynamic> json) => UserSessions(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      appVersion: json['app_version'] as String,
      provider: AiProvider.fromString(json['provider'])!,
      platform: Platform.fromString(json['platform'])!,
      sessionStart: DateTime.parse(json['session_start']),
      sessionEnd: json['session_end'] != null ? DateTime.parse(json['session_end']) : null,
      messagesSent: json['messages_sent'] as int?,
      errorsCount: json['errors_count'] as int?,
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'app_version': appVersion,
      'provider': provider.value,
      'platform': platform.value,
      'session_start': sessionStart.toIso8601String(),
      'session_end': sessionEnd?.toIso8601String(),
      'messages_sent': messagesSent,
      'errors_count': errorsCount,
      };

  UserSessions copyWith({
    String? id,
    String? userId,
    String? appVersion,
    AiProvider? provider,
    Platform? platform,
    DateTime? sessionStart,
    DateTime? sessionEnd,
    int? messagesSent,
    int? errorsCount,
  }) => UserSessions(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appVersion: appVersion ?? this.appVersion,
      provider: provider ?? this.provider,
      platform: platform ?? this.platform,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionEnd: sessionEnd ?? this.sessionEnd,
      messagesSent: messagesSent ?? this.messagesSent,
      errorsCount: errorsCount ?? this.errorsCount,
      );
}
