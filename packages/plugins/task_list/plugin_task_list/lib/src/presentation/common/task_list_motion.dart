import 'package:flutter/animation.dart';

/// Movimiento de la lista de tareas.
abstract final class TaskListMotion {
  /// Lo que tarda el panel de filtros en abrirse o cerrarse.
  static const Duration filters = Duration(milliseconds: 250);

  /// Curva del panel de filtros: arranca rápido y frena al llegar.
  static const Curve filtersCurve = Curves.easeOutCubic;
}
