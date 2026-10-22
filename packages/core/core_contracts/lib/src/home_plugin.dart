import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

abstract class HomePlugin {
  /// Identificador único e inmutable del plugin (ej. 'home_item_tracker')
  String get id;

  /// Clave i18n para el nombre localizable
  String get nameKey;

  /// Clave i18n para la descripción localizable
  String get descriptionKey;

  /// Icono representativo en el dashboard
  IconData get icon;

  /// Versión del contrato semántico del plugin
  String get version;

  /// Indica si el dispositivo cumple las capacidades físicas que requiere el
  /// plugin (etapa de Disponibilidad del ciclo de vida).
  ///
  /// La mayoría de plugins devuelven `true`. Los que dependen de hardware
  /// (cámara, NFC) deben consultarlo a través de `core_hardware`. Un plugin no
  /// disponible no se inicializa ni se renderiza, pero su preferencia de
  /// usuario se conserva.
  Future<bool> isAvailable();

  /// Invocado durante el arranque si el plugin está activado por el usuario
  Future<void> initialize();

  /// Define las rutas declarativas expuestas por el plugin
  List<RouteBase> get routes;

  /// Renderiza el Widget interactivo para la pantalla de inicio
  Widget buildDashboardTile(BuildContext context);

  /// Invocado cuando el plugin es desactivado para liberar memoria
  Future<void> dispose();
}
