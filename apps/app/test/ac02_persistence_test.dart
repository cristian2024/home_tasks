import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:core_storage/core_storage.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/bootstrap.dart';
import 'package:home_utility_app/settings/app_settings.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import 'helpers/in_memory_app_settings_repository.dart';

/// AC-02 de extremo a extremo con Isar real y el arranque real de la app:
/// desactivar, "reiniciar" (cerrar todo y volver a arrancar sobre el mismo
/// directorio) y comprobar que el plugin sigue desactivado y sus datos
/// intactos.
void main() {
  late Directory directory;
  late InMemoryAppSettingsRepository settings;

  setUpAll(() => Isar.initializeIsarCore(download: true));
  setUp(() {
    directory = Directory.systemTemp.createTempSync('ac02');
    settings = InMemoryAppSettingsRepository();
  });
  tearDown(() => directory.deleteSync(recursive: true));

  Future<AppEnvironment> start() => bootstrapApp(
        databaseDirectory: directory.path,
        systemLanguageCode: 'es',
        settingsRepository: settings,
        locator: ServiceLocator(),
        localization: LocalizationCoordinator(),
      );

  test('AC-02: la desactivación persiste tras reiniciar y los datos se conservan', () async {
    var app = await start();
    final created = await app.locator.get<ItemTrackerDependencies>().createItem(
          name: 'Caja A',
          identifier: (rawValue: 'QR-123', type: IdentifierType.qr),
        );
    await app.plugins.setEnabled(ItemTrackerPlugin.pluginId, enabled: false);
    expect(app.locator.isRegistered<ItemTrackerDependencies>(), isFalse, reason: 'dispose() libera su scope');
    await app.dispose();

    // Reinicio.
    app = await start();
    expect(app.registry.getPlugin(ItemTrackerPlugin.pluginId), isNotNull, reason: 'AC-01');
    expect(app.plugins.stateOf(ItemTrackerPlugin.pluginId)?.preference.isEnabled, isFalse);
    expect(app.plugins.dashboard, isEmpty);
    // Los datos siguen en Isar aunque el plugin esté desactivado.
    final stored = await IsarHouseholdItemRepository(app.isar!).getById(created.id);
    expect(stored?.name, 'Caja A');

    // Al reactivarlo, el plugin vuelve a encontrar sus datos.
    await app.plugins.setEnabled(ItemTrackerPlugin.pluginId, enabled: true);
    final found = await app.locator.get<ItemTrackerDependencies>().findItemByIdentifier(
          rawValue: 'QR-123',
          type: IdentifierType.qr,
        );
    expect(found?.id, created.id);
    await app.dispose();
  });

  test('el tema y el idioma elegidos se aplican al arrancar de nuevo', () async {
    AppEnvironment app = await start();
    expect(app.localization.languageCode.value, 'es');
    await app.settings.setTheme(AppThemePreference.dark);
    await app.settings.setLanguage('en');
    await app.dispose();

    app = await start();
    expect(app.settings.state, const AppSettings(theme: AppThemePreference.dark, languageCode: 'en'));
    expect(app.localization.languageCode.value, 'en');
    await app.dispose();
  });
}
