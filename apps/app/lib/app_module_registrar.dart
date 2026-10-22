import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

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
const List<PluginFactory> appPluginFactories = [_itemTracker];

HomePlugin _itemTracker(
  ServiceLocator locator,
  LocalizationCoordinator localization,
) =>
    ItemTrackerPlugin(locator: locator, localization: localization)
      ..registerLocalization();

/// Registra en un [PluginRegistry] los plugins que crean [factories].
PluginRegistry createPluginRegistry({
  required ServiceLocator locator,
  required LocalizationCoordinator localization,
  List<PluginFactory> factories = appPluginFactories,
}) {
  final registry = PluginRegistry();
  for (final factory in factories) {
    registry.register(factory(locator, localization));
  }
  return registry;
}
