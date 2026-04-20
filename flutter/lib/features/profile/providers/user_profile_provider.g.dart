// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the current user's profile
/// Automatically fetches and caches the user profile based on auth state

@ProviderFor(currentUserProfile)
const currentUserProfileProvider = CurrentUserProfileProvider._();

/// Provider for the current user's profile
/// Automatically fetches and caches the user profile based on auth state

final class CurrentUserProfileProvider
    extends $FunctionalProvider<AsyncValue<Users?>, Users?, FutureOr<Users?>>
    with $FutureModifier<Users?>, $FutureProvider<Users?> {
  /// Provider for the current user's profile
  /// Automatically fetches and caches the user profile based on auth state
  const CurrentUserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $FutureProviderElement<Users?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Users?> create(Ref ref) {
    return currentUserProfile(ref);
  }
}

String _$currentUserProfileHash() =>
    r'ea97922b5c9209b9448b79cf46bcda2e53c072a7';

/// Provider for checking if a username is available

@ProviderFor(UsernameChecker)
const usernameCheckerProvider = UsernameCheckerProvider._();

/// Provider for checking if a username is available
final class UsernameCheckerProvider
    extends $AsyncNotifierProvider<UsernameChecker, bool?> {
  /// Provider for checking if a username is available
  const UsernameCheckerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usernameCheckerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usernameCheckerHash();

  @$internal
  @override
  UsernameChecker create() => UsernameChecker();
}

String _$usernameCheckerHash() => r'4157941cdc0a4c70b088cea5db2aa3a765123514';

/// Provider for checking if a username is available

abstract class _$UsernameChecker extends $AsyncNotifier<bool?> {
  FutureOr<bool?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool?>, bool?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool?>, bool?>,
              AsyncValue<bool?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
