// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nv_cmd_ctr.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NouvelleCommandeController)
final nouvelleCommandeControllerProvider =
    NouvelleCommandeControllerProvider._();

final class NouvelleCommandeControllerProvider
    extends
        $AsyncNotifierProvider<NouvelleCommandeController, List<ClientModel>> {
  NouvelleCommandeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nouvelleCommandeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nouvelleCommandeControllerHash();

  @$internal
  @override
  NouvelleCommandeController create() => NouvelleCommandeController();
}

String _$nouvelleCommandeControllerHash() =>
    r'db2d16debff2434adefe225b82e88446284c1d98';

abstract class _$NouvelleCommandeController
    extends $AsyncNotifier<List<ClientModel>> {
  FutureOr<List<ClientModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ClientModel>>, List<ClientModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ClientModel>>, List<ClientModel>>,
              AsyncValue<List<ClientModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
