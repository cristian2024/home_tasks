import 'package:plugin_shopping_list/plugin_shopping_list.dart';

/// Valores de los accesos rápidos del icono de la app.
abstract final class AppShortcutDefaults {
  /// Como mucho, los que muestra iOS (y la mayoría de lanzadores Android).
  static const int maxShortcuts = 4;

  /// Recurso nativo del icono de cada plugin: un drawable en
  /// `android/app/src/main/res/drawable` y una imagen en
  /// `ios/Runner/Assets.xcassets` con ese nombre. Un plugin sin él sale sin
  /// icono.
  static const Map<String, String> icons = <String, String>{
    ShoppingListPlugin.pluginId: 'shortcut_shopping_list',
  };
}
