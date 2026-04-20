// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthState)
const authStateProvider = AuthStateProvider._();

final class AuthStateProvider
    extends $AsyncNotifierProvider<AuthState, AuthStateData> {
  const AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  AuthState create() => AuthState();
}

String _$authStateHash() => r'5c3d82f62109cb89a32da4cee068e619639acb41';

abstract class _$AuthState extends $AsyncNotifier<AuthStateData> {
  FutureOr<AuthStateData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<AuthStateData>, AuthStateData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthStateData>, AuthStateData>,
              AsyncValue<AuthStateData>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
