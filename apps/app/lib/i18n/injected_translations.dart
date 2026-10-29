import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

/// Paquetes cuyos textos inyecta la app, con el nombre con que se registran
/// en `LocalizationCoordinator`. La app define todos sus textos en
/// `assets/i18n/<paquete>/<idioma>.json` (§13.2).
const List<String> injectedTranslationPackages = <String>[
  'core_ui',
  ItemTrackerPlugin.pluginId,
  ShoppingListPlugin.pluginId,
];
