// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClientsController)
final clientsControllerProvider = ClientsControllerProvider._();

final class ClientsControllerProvider
    extends $AsyncNotifierProvider<ClientsController, List<ClientModel>> {
  ClientsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientsControllerHash();

  @$internal
  @override
  ClientsController create() => ClientsController();
}

String _$clientsControllerHash() => r'342411f6ba36cc0bbf82ed39f122d39d9967fa3e';

abstract class _$ClientsController extends $AsyncNotifier<List<ClientModel>> {
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
