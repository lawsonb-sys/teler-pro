// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commande_ctr.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommandesController)
final commandesControllerProvider = CommandesControllerProvider._();

final class CommandesControllerProvider
    extends $AsyncNotifierProvider<CommandesController, List<CommandeModel>> {
  CommandesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commandesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commandesControllerHash();

  @$internal
  @override
  CommandesController create() => CommandesController();
}

String _$commandesControllerHash() =>
    r'69bc1795ccf15d3a008287ff1a5fb6a24a3d4cf6';

abstract class _$CommandesController
    extends $AsyncNotifier<List<CommandeModel>> {
  FutureOr<List<CommandeModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CommandeModel>>, List<CommandeModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CommandeModel>>, List<CommandeModel>>,
              AsyncValue<List<CommandeModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
