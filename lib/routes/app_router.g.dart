// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Main app router with bottom navigation shell
///
/// Uses @riverpod annotation to generate a provider
/// This creates `appRouterProvider` automatically after build_runner

@ProviderFor(appRouter)
const appRouterProvider = AppRouterProvider._();

/// Main app router with bottom navigation shell
///
/// Uses @riverpod annotation to generate a provider
/// This creates `appRouterProvider` automatically after build_runner

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Main app router with bottom navigation shell
  ///
  /// Uses @riverpod annotation to generate a provider
  /// This creates `appRouterProvider` automatically after build_runner
  const AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'3c820bb2c508cf13a7a0b832ac52062311c98da4';
