import 'home_plugin.dart';

/// Un [HomePlugin] con una pantalla principal. La app la abre directamente
/// cuando el usuario elige el plugin en un sitio donde no cabe su tarjeta
/// (p. ej. la grilla de accesos rápidos del inicio).
///
/// Es opcional: un plugin sin ella (p. ej. con varias acciones igual de
/// importantes en su tarjeta) sigue mostrando su tarjeta.
abstract interface class HomePluginEntryRoute {
  /// Ruta absoluta de la pantalla principal; una de las de
  /// [HomePlugin.routes].
  String get entryRoute;
}
