// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the current user's AI usage statistics
/// Shows total costs, token usage, and provider breakdown

@ProviderFor(currentUserUsageStats)
const currentUserUsageStatsProvider = CurrentUserUsageStatsProvider._();

/// Provider for the current user's AI usage statistics
/// Shows total costs, token usage, and provider breakdown

final class CurrentUserUsageStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<UsageStats?>,
          UsageStats?,
          FutureOr<UsageStats?>
        >
    with $FutureModifier<UsageStats?>, $FutureProvider<UsageStats?> {
  /// Provider for the current user's AI usage statistics
  /// Shows total costs, token usage, and provider breakdown
  const CurrentUserUsageStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserUsageStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserUsageStatsHash();

  @$internal
  @override
  $FutureProviderElement<UsageStats?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UsageStats?> create(Ref ref) {
    return currentUserUsageStats(ref);
  }
}

String _$currentUserUsageStatsHash() =>
    r'eae38ab877ec93b0a8c13077a25d7103a6596826';

/// Provider for the current user's recent AI usage logs

@ProviderFor(recentUsageLogs)
const recentUsageLogsProvider = RecentUsageLogsProvider._();

/// Provider for the current user's recent AI usage logs

final class RecentUsageLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AiUsageLogs>>,
          List<AiUsageLogs>,
          FutureOr<List<AiUsageLogs>>
        >
    with
        $FutureModifier<List<AiUsageLogs>>,
        $FutureProvider<List<AiUsageLogs>> {
  /// Provider for the current user's recent AI usage logs
  const RecentUsageLogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentUsageLogsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentUsageLogsHash();

  @$internal
  @override
  $FutureProviderElement<List<AiUsageLogs>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AiUsageLogs>> create(Ref ref) {
    return recentUsageLogs(ref);
  }
}

String _$recentUsageLogsHash() => r'1100172af26adc1013a1208e9e7a13867cd4ac26';

/// Provider for usage logs filtered by provider

@ProviderFor(ProviderUsageLogs)
const providerUsageLogsProvider = ProviderUsageLogsFamily._();

/// Provider for usage logs filtered by provider
final class ProviderUsageLogsProvider
    extends $AsyncNotifierProvider<ProviderUsageLogs, List<AiUsageLogs>> {
  /// Provider for usage logs filtered by provider
  const ProviderUsageLogsProvider._({
    required ProviderUsageLogsFamily super.from,
    required AiProvider super.argument,
  }) : super(
         retry: null,
         name: r'providerUsageLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$providerUsageLogsHash();

  @override
  String toString() {
    return r'providerUsageLogsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProviderUsageLogs create() => ProviderUsageLogs();

  @override
  bool operator ==(Object other) {
    return other is ProviderUsageLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$providerUsageLogsHash() => r'32218c5049a3ebc09101ceae092c2c2b15a37ad4';

/// Provider for usage logs filtered by provider

final class ProviderUsageLogsFamily extends $Family
    with
        $ClassFamilyOverride<
          ProviderUsageLogs,
          AsyncValue<List<AiUsageLogs>>,
          List<AiUsageLogs>,
          FutureOr<List<AiUsageLogs>>,
          AiProvider
        > {
  const ProviderUsageLogsFamily._()
    : super(
        retry: null,
        name: r'providerUsageLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for usage logs filtered by provider

  ProviderUsageLogsProvider call(AiProvider provider) =>
      ProviderUsageLogsProvider._(argument: provider, from: this);

  @override
  String toString() => r'providerUsageLogsProvider';
}

/// Provider for usage logs filtered by provider

abstract class _$ProviderUsageLogs extends $AsyncNotifier<List<AiUsageLogs>> {
  late final _$args = ref.$arg as AiProvider;
  AiProvider get provider => _$args;

  FutureOr<List<AiUsageLogs>> build(AiProvider provider);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<List<AiUsageLogs>>, List<AiUsageLogs>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AiUsageLogs>>, List<AiUsageLogs>>,
              AsyncValue<List<AiUsageLogs>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for usage logs within a date range

@ProviderFor(usageLogsByDateRange)
const usageLogsByDateRangeProvider = UsageLogsByDateRangeFamily._();

/// Provider for usage logs within a date range

final class UsageLogsByDateRangeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AiUsageLogs>>,
          List<AiUsageLogs>,
          FutureOr<List<AiUsageLogs>>
        >
    with
        $FutureModifier<List<AiUsageLogs>>,
        $FutureProvider<List<AiUsageLogs>> {
  /// Provider for usage logs within a date range
  const UsageLogsByDateRangeProvider._({
    required UsageLogsByDateRangeFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'usageLogsByDateRangeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$usageLogsByDateRangeHash();

  @override
  String toString() {
    return r'usageLogsByDateRangeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<AiUsageLogs>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AiUsageLogs>> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return usageLogsByDateRange(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is UsageLogsByDateRangeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$usageLogsByDateRangeHash() =>
    r'50530b00fc9e9b9e0055e6f7bca240f024a76475';

/// Provider for usage logs within a date range

final class UsageLogsByDateRangeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<AiUsageLogs>>,
          (DateTime, DateTime)
        > {
  const UsageLogsByDateRangeFamily._()
    : super(
        retry: null,
        name: r'usageLogsByDateRangeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for usage logs within a date range

  UsageLogsByDateRangeProvider call(DateTime startDate, DateTime endDate) =>
      UsageLogsByDateRangeProvider._(
        argument: (startDate, endDate),
        from: this,
      );

  @override
  String toString() => r'usageLogsByDateRangeProvider';
}
