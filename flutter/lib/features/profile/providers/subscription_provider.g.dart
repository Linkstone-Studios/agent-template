// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the current user's subscription

@ProviderFor(currentSubscription)
const currentSubscriptionProvider = CurrentSubscriptionProvider._();

/// Provider for the current user's subscription

final class CurrentSubscriptionProvider
    extends
        $FunctionalProvider<
          AsyncValue<Subscriptions?>,
          Subscriptions?,
          FutureOr<Subscriptions?>
        >
    with $FutureModifier<Subscriptions?>, $FutureProvider<Subscriptions?> {
  /// Provider for the current user's subscription
  const CurrentSubscriptionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSubscriptionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSubscriptionHash();

  @$internal
  @override
  $FutureProviderElement<Subscriptions?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Subscriptions?> create(Ref ref) {
    return currentSubscription(ref);
  }
}

String _$currentSubscriptionHash() =>
    r'acf34be381e1456676f65faad533a93076fa9ce0';

/// Provider to check if the current user has an active subscription

@ProviderFor(hasActiveSubscription)
const hasActiveSubscriptionProvider = HasActiveSubscriptionProvider._();

/// Provider to check if the current user has an active subscription

final class HasActiveSubscriptionProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider to check if the current user has an active subscription
  const HasActiveSubscriptionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasActiveSubscriptionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasActiveSubscriptionHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasActiveSubscription(ref);
  }
}

String _$hasActiveSubscriptionHash() =>
    r'56b98ff641e8b4fbdd19b414a625c141017bfd60';

/// Provider for subscription history

@ProviderFor(subscriptionHistory)
const subscriptionHistoryProvider = SubscriptionHistoryProvider._();

/// Provider for subscription history

final class SubscriptionHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subscriptions>>,
          List<Subscriptions>,
          FutureOr<List<Subscriptions>>
        >
    with
        $FutureModifier<List<Subscriptions>>,
        $FutureProvider<List<Subscriptions>> {
  /// Provider for subscription history
  const SubscriptionHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<Subscriptions>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Subscriptions>> create(Ref ref) {
    return subscriptionHistory(ref);
  }
}

String _$subscriptionHistoryHash() =>
    r'e7dab916434110a1e292309328ef1059c72811e7';
