// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_ctr.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccueilController)
final accueilControllerProvider = AccueilControllerProvider._();

final class AccueilControllerProvider
    extends $AsyncNotifierProvider<AccueilController, AccueilData> {
  AccueilControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accueilControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accueilControllerHash();

  @$internal
  @override
  AccueilController create() => AccueilController();
}

String _$accueilControllerHash() => r'19d907665f1bd5a35f57edc3adad97e6c6a3a072';

abstract class _$AccueilController extends $AsyncNotifier<AccueilData> {
  FutureOr<AccueilData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AccueilData>, AccueilData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AccueilData>, AccueilData>,
              AsyncValue<AccueilData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
