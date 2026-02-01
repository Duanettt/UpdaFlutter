// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'articles_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Articles)
const articlesProvider = ArticlesFamily._();

final class ArticlesProvider
    extends $AsyncNotifierProvider<Articles, List<Article>> {
  const ArticlesProvider._({
    required ArticlesFamily super.from,
    required (int, String) super.argument,
  }) : super(
         retry: null,
         name: r'articlesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$articlesHash();

  @override
  String toString() {
    return r'articlesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  Articles create() => Articles();

  @override
  bool operator ==(Object other) {
    return other is ArticlesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articlesHash() => r'38623ed4540181fd7268fdb2b6ff74c813dcb1eb';

final class ArticlesFamily extends $Family
    with
        $ClassFamilyOverride<
          Articles,
          AsyncValue<List<Article>>,
          List<Article>,
          FutureOr<List<Article>>,
          (int, String)
        > {
  const ArticlesFamily._()
    : super(
        retry: null,
        name: r'articlesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ArticlesProvider call(int topicId, String topicName) =>
      ArticlesProvider._(argument: (topicId, topicName), from: this);

  @override
  String toString() => r'articlesProvider';
}

abstract class _$Articles extends $AsyncNotifier<List<Article>> {
  late final _$args = ref.$arg as (int, String);
  int get topicId => _$args.$1;
  String get topicName => _$args.$2;

  FutureOr<List<Article>> build(int topicId, String topicName);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2);
    final ref = this.ref as $Ref<AsyncValue<List<Article>>, List<Article>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Article>>, List<Article>>,
              AsyncValue<List<Article>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
