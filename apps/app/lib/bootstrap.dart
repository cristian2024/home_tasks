import 'dart:developer' as developer;

import 'package:core_app_shortcuts/core_app_shortcuts.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_spaces/core_spaces.dart';
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
import 'shortcuts/app_shortcuts_publisher.dart';
import 'spaces/device_environment.dart';
import 'spaces/space_household_tracker.dart';
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
    this.shortcuts,
    this.device,
    this.space,
    this.householdTracker,
  });

  final ServiceLocator locator;
  final LocalizationCoordinator localization;
  final PluginRegistry registry;
  final PluginController plugins;

  /// Tema e idioma elegidos por el usuario.
  final AppSettingsController settings;

  /// Sincronización con otros dispositivos, o `null` si no se compuso.
  final SyncServices? sync;

  /// Accesos rápidos del icono, o `null` si ningún adaptador registró
  /// `AppShortcutService`.
  final AppShortcutsPublisher? shortcuts;

  /// Servicios del dispositivo (lista de espacios, accesos rápidos), o `null`
  /// sin espacios (tests). No se liberan con este entorno.
  final DeviceEnvironment? device;

  /// Espacio de datos abierto, tal como estaba al abrirlo (el nombre puede
  /// cambiar después: la lista está en [device]).
  final DataSpace? space;

  /// Anota en la lista de espacios el hogar de [space].
  final SpaceHouseholdTracker? householdTracker;

  /// Libera los plugins y los servicios; los adaptadores liberan con el
  /// locator lo que abrieron, p. ej. la base de datos (tests, reinicios y
  /// cambios de espacio). Los servicios de [device] siguen vivos.
  Future<void> dispose() async {
    shortcuts?.dispose();
    householdTracker?.dispose();
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
/// 2. Adaptadores elegidos (`appAdaptersFor`): cada uno abre sus recursos (p. ej.
///    la base de datos) y registra sus contratos en el `ServiceLocator`.
/// 3. Registro de plugins en tiempo de compilación ([appPluginFactories]).
/// 4. Ciclo de vida: inicializa los plugins activos y disponibles, con el
///    `PluginPreferenceRepository` que registró un adaptador.
/// 5. Sincronización, si un adaptador la compuso (`SyncModule`): empieza a
///    seguir el hogar y los cambios. La app la pausa y reanuda con el ciclo
///    de vida.
/// 6. Accesos rápidos del icono, si un adaptador registró
///    `AppShortcutService` (en [device] o en el espacio): publica los plugins
///    del inicio y los sigue.
///
/// Con [device] y [space], abre ese espacio de datos (por defecto,
/// `appAdaptersFor(space: space)`) y anota su hogar en la lista de espacios.
Future<AppEnvironment> bootstrapApp({
  required String systemLanguageCode,
  DeviceEnvironment? device,
  DataSpace? space,
  List<DependencyModule>? adapters,
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
  for (final DependencyModule adapter in adapters ?? appAdaptersFor(space: space)) {
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

  final AppShortcutService? shortcutService = device?.shortcuts ??
      (services.isRegistered<AppShortcutService>() ? services.get<AppShortcutService>() : null);
  final AppShortcutsPublisher? shortcuts = shortcutService == null
      ? null
      : (AppShortcutsPublisher(service: shortcutService, plugins: plugins, localization: l10n)..start());

  SpaceHouseholdTracker? householdTracker;
  if (device != null && space != null && sync != null) {
    householdTracker =
        SpaceHouseholdTracker(directory: device.spaces, spaceId: space.id, households: sync.households);
    await householdTracker.start();
  }

  return AppEnvironment(
    locator: services,
    localization: l10n,
    registry: registry,
    plugins: plugins,
    settings: settings,
    sync: sync,
    shortcuts: shortcuts,
    device: device,
    space: space,
    householdTracker: householdTracker,
  );
}
