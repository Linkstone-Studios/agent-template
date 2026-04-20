// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: subscriptions

enum SubscriptionStatus {
  active('active'),
  cancelled('cancelled'),
  expired('expired'),
  trialing('trialing');

  const SubscriptionStatus(this.value);
  final String value;

  static SubscriptionStatus? fromString(String? value) {
    if (value == null) return null;
    try {
      return SubscriptionStatus.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

class Subscriptions {
  final String id;
  final String userId;
  final SubscriptionStatus status;
  final String planId;
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  const Subscriptions({
    required this.id,
    required this.userId,
    required this.status,
    required this.planId,
    this.stripeSubscriptionId,
    this.stripeCustomerId,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  factory Subscriptions.fromJson(Map<String, dynamic> json) => Subscriptions(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: SubscriptionStatus.fromString(json['status'])!,
      planId: json['plan_id'] as String,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      stripeCustomerId: json['stripe_customer_id'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'status': status.value,
      'plan_id': planId,
      'stripe_subscription_id': stripeSubscriptionId,
      'stripe_customer_id': stripeCustomerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      };

  Subscriptions copyWith({
    String? id,
    String? userId,
    SubscriptionStatus? status,
    String? planId,
    String? stripeSubscriptionId,
    String? stripeCustomerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) => Subscriptions(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      planId: planId ?? this.planId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      );
}
