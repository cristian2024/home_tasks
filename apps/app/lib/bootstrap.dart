import 'dart:developer' as developer;

import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/services.dart';

import 'app_module_registrar.dart';
import 'i18n/injected_translations.dart';
import 'i18n/strings.g.dart' as i18n;
import 'plugins/plugin_controller.dart';
import 'settings/app_settings.dart';
import 'settings/app_settings_controller.dart';
import 'settings/app_settings_repository.dart';
import 'sync/sync_services.dart';

/// Todo lo que la app necesita tras arrancar.
class AppEnvironment {
  AppEnvironment({
    required this.locator,
    required this.localization,
    required this.registry,
    required this.plugins,
    required this.settings,
    this.sync,
  });

  final ServiceLocator locator;
  final LocalizationCoordinator localization;
  final PluginRegistry registry;
  final PluginController plugins;

  /// Tema e idioma elegidos por el usuario.
  final AppSettingsController settings;

  /// Sincronización con otros dispositivos, o `null` si no se compuso.
  final SyncServices? sync;

  /// Libera los plugins y los servicios; los adaptadores liberan con el
  /// locator lo que abrieron, p. ej. la base de datos (tests y reinicios).
  Future<void> dispose() async {
    await sync?.controller.stop();
    await plugins.disposePlugins();
    plugins.dispose();
    await settings.close();
    await locator.reset();
  }
}

/// Arranque de la app (§3.2, §10.2):
/// 1. Textos que la app inyecta en los paquetes (de [assetBundle], por
///    defecto `rootBundle`), preferencias de la app (tema e idioma;
///    [systemLanguageCode] si el usuario no fijó uno) y servicios base en el
///    scope raíz de `core_di`.
/// 2. Adaptadores elegidos ([appAdapters]): cada uno abre sus recursos (p. ej.
///    la base de datos) y registra sus contratos en el `ServiceLocator`.
/// 3. Registro de plugins en tiempo de compilación ([appPluginFactories]).
/// 4. Ciclo de vida: inicializa los plugins activos y disponibles, con el
///    `PluginPreferenceRepository` que registró un adaptador.
/// 5. Sincronización, si un adaptador la compuso (`SyncModule`): empieza a
///    seguir el hogar y los cambios. La app la pausa y reanuda con el ciclo
///    de vida.
Future<AppEnvironment> bootstrapApp({
  required String systemLanguageCode,
  List<DependencyModule> adapters = appAdapters,
  AppSettingsRepository settingsRepository = const SharedPreferencesAppSettingsRepository(),
  AssetBundle? assetBundle,
  ServiceLocator? locator,
  LocalizationCoordinator? localization,
  List<PluginFactory> pluginFactories = appPluginFactories,
}) async {
  final ServiceLocator services = locator ?? ServiceLocator.instance;
  final LocalizationCoordinator l10n = localization ?? LocalizationCoordinator.instance;
  l10n.register(
    'app',
    (String code) => i18n.LocaleSettings.setLocaleRawSync(code),
    translate: (String key) {
      final Object? value = i18n.appStrings[key];
      return value is String ? value : null;
    },
  );
  await injectTranslations(l10n, bundle: assetBundle ?? rootBundle, packages: injectedTranslationPackages);
  final AppSettings savedSettings = await settingsRepository.load();
  final AppSettingsController settings = AppSettingsController(
    repository: settingsRepository,
    localization: l10n,
    initial: savedSettings,
    systemLanguageCode: systemLanguageCode,
  );

  services
    ..registerSingleton<EventBus>(EventBus(), dispose: (EventBus bus) => bus.dispose())
    ..registerSingleton<IdGenerator>(const UuidV4Generator())
    ..registerSingleton<Clock>(const SystemClock());
  for (final DependencyModule adapter in adapters) {
    await adapter.register(services);
  }

  final PluginRegistry registry = createPluginRegistry(
    locator: services,
    localization: l10n,
    factories: pluginFactories,
  );

  final PluginController plugins = PluginController(
    PluginLifecycleManager(
      registry: registry,
      preferences: services.get<PluginPreferenceRepository>(),
      onError: (String pluginId, Object error, StackTrace stackTrace) => developer.log(
        'El plugin $pluginId falló',
        name: 'home_utility_app',
        error: error,
        stackTrace: stackTrace,
      ),
    ),
  );
  await plugins.load();

  final SyncServices? sync = SyncServices.of(services);
  await sync?.controller.start();

  return AppEnvironment(
    locator: services,
    localization: l10n,
    registry: registry,
    plugins: plugins,
    settings: settings,
    sync: sync,
  );
}
