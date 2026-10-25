import 'dart:developer' as developer;

import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_storage/core_storage.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/services.dart';

import 'app_module_registrar.dart';
import 'i18n/strings.g.dart' as i18n;
import 'i18n/translation_overrides.dart';
import 'plugins/plugin_controller.dart';
import 'settings/app_settings.dart';
import 'settings/app_settings_controller.dart';
import 'settings/app_settings_repository.dart';

/// Todo lo que la app necesita tras arrancar.
class AppEnvironment {
  AppEnvironment({
    required this.locator,
    required this.localization,
    required this.registry,
    required this.plugins,
    required this.settings,
    this.isar,
  });

  final ServiceLocator locator;
  final LocalizationCoordinator localization;
  final PluginRegistry registry;
  final PluginController plugins;

  /// Tema e idioma elegidos por el usuario.
  final AppSettingsController settings;

  /// `null` en los widget tests, que usan repositorios en memoria.
  final Isar? isar;

  /// Libera los plugins, los servicios y la base de datos (tests y reinicios).
  Future<void> dispose() async {
    await plugins.disposePlugins();
    plugins.dispose();
    await settings.close();
    await locator.reset();
    if (isar?.isOpen ?? false) {
      await isar!.close();
    }
  }
}

/// Arranque de la app (§3.2, §10.2):
/// 1. Textos que la app reemplaza en los paquetes (de [assetBundle], por
///    defecto `rootBundle`), preferencias de la app (tema e idioma;
///    [systemLanguageCode] si el usuario no fijó uno) y servicios base en el
///    scope raíz de `core_di`.
/// 2. Registro de plugins en tiempo de compilación ([appPluginFactories]).
/// 3. Base de datos con los esquemas de **todos** los plugins registrados,
///    también los desactivados (sus datos deben seguir accesibles, AC-02).
/// 4. Ciclo de vida: inicializa los plugins activos y disponibles.
Future<AppEnvironment> bootstrapApp({
  required String databaseDirectory,
  required String systemLanguageCode,
  AppSettingsRepository settingsRepository = const SharedPreferencesAppSettingsRepository(),
  AssetBundle? assetBundle,
  ServiceLocator? locator,
  LocalizationCoordinator? localization,
  List<PluginFactory> pluginFactories = appPluginFactories,
  String databaseName = Isar.defaultName,
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
  await applyTranslationOverrides(l10n, bundle: assetBundle ?? rootBundle);
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

  final PluginRegistry registry = createPluginRegistry(
    locator: services,
    localization: l10n,
    factories: pluginFactories,
  );

  final Isar isar = await LocalDatabase.open(
    directory: databaseDirectory,
    name: databaseName,
    contributors: registry.allPlugins.whereType<StorageSchemaContributor>(),
  );
  services.registerSingleton<Isar>(isar);

  final PluginController plugins = PluginController(
    PluginLifecycleManager(
      registry: registry,
      preferences: IsarPluginPreferenceRepository(isar),
      onError: (String pluginId, Object error, StackTrace stackTrace) => developer.log(
        'El plugin $pluginId falló',
        name: 'home_utility_app',
        error: error,
        stackTrace: stackTrace,
      ),
    ),
  );
  await plugins.load();

  return AppEnvironment(
    locator: services,
    localization: l10n,
    registry: registry,
    plugins: plugins,
    settings: settings,
    isar: isar,
  );
}
