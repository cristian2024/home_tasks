import 'package:flutter_test/flutter_test.dart';
import 'package:qr_display/qr_display.dart';

/// Comprueba el patrón de posición (el cuadro de 7×7 de las esquinas) con su
/// esquina superior izquierda en [top], [left].
void expectFinderPattern(QrMatrix matrix, int top, int left) {
  for (int row = 0; row < 7; row++) {
    for (int column = 0; column < 7; column++) {
      final bool border = row == 0 || row == 6 || column == 0 || column == 6;
      final bool center = row >= 2 && row <= 4 && column >= 2 && column <= 4;
      expect(matrix.isDark(top + row, left + column), border || center, reason: 'módulo ($row, $column)');
    }
  }
}

void main() {
  test('un texto corto cabe en la versión 1 (21×21) con los patrones de las tres esquinas', () {
    final QrMatrix matrix = QrMatrix.encode('hola');

    expect(matrix.size, 21);
    expectFinderPattern(matrix, 0, 0);
    expectFinderPattern(matrix, 0, matrix.size - 7);
    expectFinderPattern(matrix, matrix.size - 7, 0);
  });

  test('la misma entrada da siempre los mismos módulos', () {
    final QrMatrix a = QrMatrix.encode('household:abc');
    final QrMatrix b = QrMatrix.encode('household:abc');

    for (int row = 0; row < a.size; row++) {
      for (int column = 0; column < a.size; column++) {
        expect(a.isDark(row, column), b.isDark(row, column));
      }
    }
  });

  test('más datos o más corrección de errores necesitan un QR más grande', () {
    final String data = 'x' * 100;

    final int medium = QrMatrix.encode(data).size;
    expect(QrMatrix.encode('x' * 1000).size, greaterThan(medium));
    expect(QrMatrix.encode(data, errorLevel: QrErrorLevel.high).size, greaterThan(medium));
    expect(QrMatrix.encode(data, errorLevel: QrErrorLevel.quartile).size, greaterThan(medium));
    expect(QrMatrix.encode(data, errorLevel: QrErrorLevel.low).size, lessThanOrEqualTo(medium));
  });

  test('un texto de 2000 caracteres base64url cabe', () {
    // Las minúsculas y `-`/`_` obligan al modo byte, el menos compacto.
    expect(QrMatrix.encode('aB-_' * 500).size, lessThanOrEqualTo(177));
  });

  test('lanza ArgumentError si los datos no caben en un QR', () {
    expect(() => QrMatrix.encode('x' * 3000), throwsArgumentError);
  });

  test('isDark fuera de la matriz lanza RangeError', () {
    final QrMatrix matrix = QrMatrix.encode('hola');

    expect(() => matrix.isDark(-1, 0), throwsRangeError);
    expect(() => matrix.isDark(0, matrix.size), throwsRangeError);
  });
}
