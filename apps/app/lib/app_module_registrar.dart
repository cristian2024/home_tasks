import 'package:app_shortcuts_quick_actions/app_shortcuts_quick_actions.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_spaces/core_spaces.dart';
import 'package:core_ui/core_ui.dart';
import 'package:hardware_mobile_scanner/hardware_mobile_scanner.dart';
import 'package:hardware_nfc_manager/hardware_nfc_manager.dart';
import 'package:hardware_permission_handler/hardware_permission_handler.dart';
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:secret_store_secure_storage/secret_store_secure_storage.dart';
import 'package:share_native/share_native.dart';
import 'package:shopping_list_isar/shopping_list_isar.dart';
import 'package:spaces_shared_preferences/spaces_shared_preferences.dart';
import 'package:storage_isar/storage_isar.dart';
import 'package:sync_crypto_cryptography/sync_crypto_cryptography.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_isar/sync_isar.dart';
import 'package:sync_lan/sync_lan.dart';

import 'spaces/space_defaults.dart';

/// Adaptadores del dispositivo, que no dependen del espacio de datos: la
/// lista de espacios (`shared_preferences`) y los accesos rápidos del icono
/// (quick_actions). Se componen una vez y sobreviven a los cambios de espacio.
const List<DependencyModule> deviceAdapters = <DependencyModule>[
  SharedPreferencesSpaces(),
  QuickActionsShortcuts(),
];

/// Bases de los espacios de datos: las de Isar, en la carpeta de documentos.
const Future<DataSpaceStorage> Function() appSpaceStorage = IsarSpaceStorage.documents;

/// Adaptadores del espacio de datos [space] (sin él, la base de siempre).
/// Cada uno abre sus recursos y registra sus contratos en el
/// `ServiceLocator`; la app solo los elige. Incluye los adaptadores de
/// **todos** los plugins registrados, también los desactivados, para que sus
/// datos sigan accesibles (AC-02).
///
/// La sincronización: `SyncIsar` (estado y log en la misma base),
/// almacén seguro para la clave del hogar, cifrado, transporte por la WiFi y,
/// **al final**, `SyncModule`, que compone el motor con lo anterior. Con
/// [deviceName], el nombre de este dispositivo si la base es nueva.
List<DependencyModule> appAdaptersFor({DataSpace? space, String? deviceName}) => <DependencyModule>[
      IsarStorage(
        name: space?.databaseName ?? SpaceDefaults.legacyDatabaseName,
        features: const <IsarFeature>[ItemTrackerIsar(), ShoppingListIsar(), SyncIsar()],
      ),
      const NativeShare(),
      const MobileScannerHardware(),
      const NfcManagerHardware(),
      const PermissionHandlerHardware(),
      const SecureStorageSecrets(),
      const CryptographySyncCipher(),
      const LanSyncTransport(),
      deviceName == null ? const SyncModule() : SyncModule(deviceName: deviceName),
    ];

/// Crea un plugin con los servicios de la app. Además de construirlo, debe
/// registrar sus traducciones para que el catálogo pueda mostrar su nombre
/// aunque esté desactivado.
typedef PluginFactory =
    HomePlugin Function(
      ServiceLocator locator,
      LocalizationCoordinator localization,
    );

/// Registro en tiempo de compilación de todos los plugins conocidos (§3.2).
/// Para añadir un plugin: dependencia en `pubspec.yaml` y una entrada aquí.
const List<PluginFactory> appPluginFactories = <PluginFactory>[_itemTracker, _shoppingList];

HomePlugin _itemTracker(
  ServiceLocator locator,
  LocalizationCoordinator localization,
) =>
    ItemTrackerPlugin(locator: locator, localization: localization)
      ..registerLocalization();

HomePlugin _shoppingList(
  ServiceLocator locator,
  LocalizationCoordinator localization,
) =>
    ShoppingListPlugin(locator: locator, localization: localization)
      ..registerLocalization();

/// Registra en un [PluginRegistry] los plugins que crean [factories].
PluginRegistry createPluginRegistry({
  required ServiceLocator locator,
  required LocalizationCoordinator localization,
  List<PluginFactory> factories = appPluginFactories,
}) {
  final PluginRegistry registry = PluginRegistry();
  for (final PluginFactory factory in factories) {
    registry.register(factory(locator, localization));
  }
  return registry;
}
