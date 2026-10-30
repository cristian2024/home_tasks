import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/testing.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/bootstrap.dart';
import 'package:home_utility_app/settings/app_settings.dart';
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:shopping_list_isar/shopping_list_isar.dart';
import 'package:storage_isar/adapter.dart' show Isar;
import 'package:storage_isar/storage_isar.dart';

import 'helpers/in_memory_app_settings_repository.dart';

/// Hardware falso en lugar de los adaptadores nativos, que necesitan un
/// dispositivo.
class _FakeHardware implements DependencyModule {
  const _FakeHardware();

  @override
  Future<void> register(ServiceLocator services) async => services
    ..registerFactory<CameraIdentifierScanner>(FakeCameraScanner.new)
    ..registerFactory<NfcIdentifierScanner>(FakeNfcScanner.new)
    ..registerSingleton<HardwarePermissions>(FakeHardwarePermissions());
}

/// AC-02 de extremo a extremo con Isar real y el arranque real de la app:
/// desactivar, "reiniciar" (cerrar todo y volver a arrancar sobre el mismo
/// directorio) y comprobar que el plugin sigue desactivado y sus datos
/// intactos.
void main() {
  late Directory directory;
  late InMemoryAppSettingsRepository settings;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    // bootstrapApp lee de rootBundle los textos que la app reemplaza. El
    // binding de test responde 400 a toda petición HTTP, así que se inicia
    // después de descargar libisar (en CI no está en caché).
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  setUp(() {
    directory = Directory.systemTemp.createTempSync('ac02');
    settings = InMemoryAppSettingsRepository();
  });
  tearDown(() => directory.deleteSync(recursive: true));

  // Los adaptadores reales, con la base en un directorio temporal.
  Future<AppEnvironment> start() => bootstrapApp(
        adapters: <DependencyModule>[
          IsarStorage(
            directory: directory.path,
            features: const <IsarFeature>[ItemTrackerIsar(), ShoppingListIsar()],
          ),
          const _FakeHardware(),
        ],
        systemLanguageCode: 'es',
        settingsRepository: settings,
        locator: ServiceLocator(),
        localization: LocalizationCoordinator(),
      );

  test('AC-02: la desactivación persiste tras reiniciar y los datos se conservan', () async {
    AppEnvironment app = await start();
    final HouseholdItem created = await app.locator.get<ItemTrackerDependencies>().createItem(
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
    expect(
      app.plugins.dashboard.map((PluginState state) => state.plugin.id),
      isNot(contains(ItemTrackerPlugin.pluginId)),
    );
    // Los datos siguen guardados aunque el plugin esté desactivado.
    final HouseholdItem? stored = await app.locator.get<HouseholdItemRepository>().getById(created.id);
    expect(stored?.name, 'Caja A');

    // Al reactivarlo, el plugin vuelve a encontrar sus datos.
    await app.plugins.setEnabled(ItemTrackerPlugin.pluginId, enabled: true);
    final HouseholdItem? found = await app.locator.get<ItemTrackerDependencies>().findItemByIdentifier(
          rawValue: 'QR-123',
          type: IdentifierType.qr,
        );
    expect(found?.id, created.id);
    await app.dispose();
  });

  test('AC-02: la lista de compras desactivada conserva sus items, categorías e historial', () async {
    AppEnvironment app = await start();
    final ShoppingListDependencies deps = app.locator.get<ShoppingListDependencies>();
    final ShoppingItem eggs = await deps.createItem(name: 'Huevos', recurrence: Recurrence.between(8, 15));
    await deps.markPurchased(eggs.id);
    await app.plugins.setEnabled(ShoppingListPlugin.pluginId, enabled: false);
    expect(app.locator.isRegistered<ShoppingListDependencies>(), isFalse, reason: 'dispose() libera su scope');
    await app.dispose();

    app = await start();
    expect(app.plugins.stateOf(ShoppingListPlugin.pluginId)?.preference.isEnabled, isFalse);
    final ShoppingListRepository repository = app.locator.get<ShoppingListRepository>();
    expect((await repository.getItem(eggs.id))?.lastPurchasedAt, isNotNull);
    expect(await repository.getPurchases(eggs.id), hasLength(1));
    expect(await repository.getCategories(), hasLength(5));

    // Al reactivarlo no se vuelven a crear las categorías por defecto.
    await app.plugins.setEnabled(ShoppingListPlugin.pluginId, enabled: true);
    expect(await repository.getCategories(), hasLength(5));
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
