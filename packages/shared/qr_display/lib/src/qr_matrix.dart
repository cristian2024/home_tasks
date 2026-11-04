import 'package:qr/qr.dart';

/// Nivel de corrección de errores: cuánto del código puede perderse (una
/// mancha, un reflejo) y seguir leyéndose. Cuanto más alto, más módulos.
enum QrErrorLevel {
  /// ~7 %.
  low(QrErrorCorrectLevel.low),

  /// ~15 %. Es el valor por defecto.
  medium(QrErrorCorrectLevel.medium),

  /// ~25 %.
  quartile(QrErrorCorrectLevel.quartile),

  /// ~30 %.
  high(QrErrorCorrectLevel.high);

  const QrErrorLevel(this._level);

  final QrErrorCorrectLevel _level;
}

/// Los módulos (cuadros) de un código QR ya codificado, sin el margen.
///
/// Es independiente de cómo se dibuje: [AppQrCode] lo pinta en pantalla, pero
/// sirve también para otra salida (SVG, impresión).
class QrMatrix {
  QrMatrix._(this.size, this._dark);

  /// Codifica [data] (UTF-8) con el modo más compacto y la versión mínima en
  /// la que cabe.
  ///
  /// Lanza [ArgumentError] si [data] no cabe en un QR (versión 40), p. ej.
  /// más de 2331 bytes con [QrErrorLevel.medium].
  factory QrMatrix.encode(String data, {QrErrorLevel errorLevel = QrErrorLevel.medium}) {
    final QrCode code;
    try {
      code = QrCode(payload: QrPayload.fromString(data), errorCorrectLevel: errorLevel._level);
    } on InputTooLongException catch (error) {
      throw ArgumentError.value(data.length, 'data', 'No cabe en un código QR ($error)');
    }
    final QrImage image = QrImage(code);
    final List<bool> dark = <bool>[
      for (int row = 0; row < image.moduleCount; row++)
        for (int column = 0; column < image.moduleCount; column++) image.isDark(row, column),
    ];
    return QrMatrix._(image.moduleCount, List<bool>.unmodifiable(dark));
  }

  /// Módulos por lado (21 en la versión 1, 4 más por cada versión).
  final int size;

  final List<bool> _dark;

  /// Si el módulo de la fila [row] y la columna [column] es oscuro.
  bool isDark(int row, int column) {
    RangeError.checkValueInInterval(row, 0, size - 1, 'row');
    RangeError.checkValueInInterval(column, 0, size - 1, 'column');
    return _dark[row * size + column];
  }
}
