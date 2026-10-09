// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paiement_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PaiementController)
final paiementControllerProvider = PaiementControllerFamily._();

final class PaiementControllerProvider
    extends $AsyncNotifierProvider<PaiementController, PaiementDataState> {
  PaiementControllerProvider._({
    required PaiementControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'paiementControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$paiementControllerHash();

  @override
  String toString() {
    return r'paiementControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PaiementController create() => PaiementController();

  @override
  bool operator ==(Object other) {
    return other is PaiementControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$paiementControllerHash() =>
    r'd193b0fb74da240383085352a1832399b2761272';

final class PaiementControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PaiementController,
          AsyncValue<PaiementDataState>,
          PaiementDataState,
          FutureOr<PaiementDataState>,
          String
        > {
  PaiementControllerFamily._()
    : super(
        retry: null,
        name: r'paiementControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PaiementControllerProvider call(String commandeId) =>
      PaiementControllerProvider._(argument: commandeId, from: this);

  @override
  String toString() => r'paiementControllerProvider';
}

abstract class _$PaiementController extends $AsyncNotifier<PaiementDataState> {
  late final _$args = ref.$arg as String;
  String get commandeId => _$args;

  FutureOr<PaiementDataState> build(String commandeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PaiementDataState>, PaiementDataState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PaiementDataState>, PaiementDataState>,
              AsyncValue<PaiementDataState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
