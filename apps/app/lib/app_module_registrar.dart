import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:share_native/share_native.dart';
import 'package:shopping_list_isar/shopping_list_isar.dart';
import 'package:storage_isar/storage_isar.dart';

/// Adaptadores que usa la app. Cada uno abre sus recursos y registra sus
/// contratos en el `ServiceLocator`; la app solo los elige. Incluye los
/// adaptadores de **todos** los plugins registrados, también los
/// desactivados, para que sus datos sigan accesibles (AC-02).
const List<DependencyModule> appAdapters = <DependencyModule>[
  IsarStorage(features: <IsarFeature>[ItemTrackerIsar(), ShoppingListIsar()]),
  NativeShare(),
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
