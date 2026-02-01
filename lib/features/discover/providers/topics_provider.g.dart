// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Topics)
const topicsProvider = TopicsProvider._();

final class TopicsProvider extends $AsyncNotifierProvider<Topics, List<Topic>> {
  const TopicsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topicsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topicsHash();

  @$internal
  @override
  Topics create() => Topics();
}

String _$topicsHash() => r'544a1a72efe6529aee3f4d3e8a3fc1081c31e4a2';

abstract class _$Topics extends $AsyncNotifier<List<Topic>> {
  FutureOr<List<Topic>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Topic>>, List<Topic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Topic>>, List<Topic>>,
              AsyncValue<List<Topic>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
