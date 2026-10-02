// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(commandesRepo)
final commandesRepoProvider = CommandesRepoProvider._();

final class CommandesRepoProvider
    extends
        $FunctionalProvider<
          OfflineRepository,
          OfflineRepository,
          OfflineRepository
        >
    with $Provider<OfflineRepository> {
  CommandesRepoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commandesRepoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commandesRepoHash();

  @$internal
  @override
  $ProviderElement<OfflineRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OfflineRepository create(Ref ref) {
    return commandesRepo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineRepository>(value),
    );
  }
}

String _$commandesRepoHash() => r'3d464564a7f9e144f3e6305b08da8947d56a3e1f';

@ProviderFor(ateliersRepo)
final ateliersRepoProvider = AteliersRepoProvider._();

final class AteliersRepoProvider
    extends
        $FunctionalProvider<
          OfflineRepository,
          OfflineRepository,
          OfflineRepository
        >
    with $Provider<OfflineRepository> {
  AteliersRepoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ateliersRepoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ateliersRepoHash();

  @$internal
  @override
  $ProviderElement<OfflineRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OfflineRepository create(Ref ref) {
    return ateliersRepo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineRepository>(value),
    );
  }
}

String _$ateliersRepoHash() => r'feb4b7bdee2b9826fc1485ac973bece17c623ff1';

@ProviderFor(clientsRepo)
final clientsRepoProvider = ClientsRepoProvider._();

final class ClientsRepoProvider
    extends
        $FunctionalProvider<
          OfflineRepository,
          OfflineRepository,
          OfflineRepository
        >
    with $Provider<OfflineRepository> {
  ClientsRepoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientsRepoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientsRepoHash();

  @$internal
  @override
  $ProviderElement<OfflineRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OfflineRepository create(Ref ref) {
    return clientsRepo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineRepository>(value),
    );
  }
}

String _$clientsRepoHash() => r'4ddd8b4c00063d04b23733a3b2c7ca8b2072a8a0';

@ProviderFor(SyncManager)
final syncManagerProvider = SyncManagerProvider._();

final class SyncManagerProvider
    extends $AsyncNotifierProvider<SyncManager, void> {
  SyncManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncManagerHash();

  @$internal
  @override
  SyncManager create() => SyncManager();
}

String _$syncManagerHash() => r'9bd7fa4f7cf750540cd584a4505b71fa0db10091';

abstract class _$SyncManager extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
