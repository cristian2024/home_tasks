import 'package:flutter/widgets.dart';

/// Valores por defecto de [AppQrCode] y [QrPainter].
abstract final class QrDefaults {
  /// Módulos oscuros en negro: muchos lectores no leen un QR invertido.
  static const Color color = Color(0xFF000000);

  /// Fondo y margen en blanco.
  static const Color backgroundColor = Color(0xFFFFFFFF);

  /// Margen en módulos que pide el estándar.
  static const int quietZone = 4;
}
