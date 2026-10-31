import 'package:flutter/widgets.dart';

import 'qr_matrix.dart';

/// Dibuja [data] como un código QR cuadrado que ocupa el ancho disponible (o
/// [size]).
///
/// Por defecto es negro sobre blanco también en el tema oscuro: muchos
/// lectores no leen un QR invertido. Lleva alrededor el margen en blanco que
/// pide el estándar ([quietZone] módulos).
///
/// Lanza [ArgumentError] al construirse si [data] no cabe en un QR (ver
/// [QrMatrix.encode]).
class AppQrCode extends StatefulWidget {
  const AppQrCode({
    super.key,
    required this.data,
    required this.semanticLabel,
    this.size,
    this.errorLevel = QrErrorLevel.medium,
    this.color = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.quietZone = 4,
  }) : assert(quietZone >= 0);

  /// Lo que codifica el QR.
  final String data;

  /// Lo que anuncia el lector de pantalla (p. ej. «Código para unirse al
  /// hogar»). El contenido no se lee: suele ser largo y no se entiende.
  final String semanticLabel;

  /// Lado en píxeles lógicos. Sin él, ocupa el ancho disponible.
  final double? size;

  final QrErrorLevel errorLevel;

  /// Color de los módulos oscuros.
  final Color color;

  /// Color del fondo y del margen.
  final Color backgroundColor;

  /// Margen en módulos. El estándar pide 4.
  final int quietZone;

  @override
  State<AppQrCode> createState() => _AppQrCodeState();
}

class _AppQrCodeState extends State<AppQrCode> {
  late QrMatrix _matrix;

  @override
  void initState() {
    super.initState();
    _matrix = QrMatrix.encode(widget.data, errorLevel: widget.errorLevel);
  }

  @override
  void didUpdateWidget(AppQrCode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.errorLevel != widget.errorLevel) {
      _matrix = QrMatrix.encode(widget.data, errorLevel: widget.errorLevel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget code = AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: QrPainter(
          matrix: _matrix,
          color: widget.color,
          backgroundColor: widget.backgroundColor,
          quietZone: widget.quietZone,
        ),
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      excludeSemantics: true,
      child: widget.size == null ? code : SizedBox.square(dimension: widget.size, child: code),
    );
  }
}

/// Pinta una [QrMatrix] centrada en el lienzo, con [quietZone] módulos de
/// margen en [backgroundColor].
///
/// Une los módulos oscuros contiguos de cada fila en un solo rectángulo, así
/// no aparecen líneas finas entre ellos al escalar.
class QrPainter extends CustomPainter {
  const QrPainter({
    required this.matrix,
    this.color = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.quietZone = 4,
  });

  final QrMatrix matrix;
  final Color color;
  final Color backgroundColor;
  final int quietZone;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = size.shortestSide;
    final Offset origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    canvas.drawRect(origin & Size.square(side), Paint()..color = backgroundColor);

    final double module = side / (matrix.size + 2 * quietZone);
    final Offset start = origin + Offset(module * quietZone, module * quietZone);
    final Path path = Path();
    for (int row = 0; row < matrix.size; row++) {
      int column = 0;
      while (column < matrix.size) {
        if (!matrix.isDark(row, column)) {
          column++;
          continue;
        }
        final int runStart = column;
        while (column < matrix.size && matrix.isDark(row, column)) {
          column++;
        }
        path.addRect(
          Rect.fromLTWH(start.dx + runStart * module, start.dy + row * module, (column - runStart) * module, module),
        );
      }
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(QrPainter oldDelegate) =>
      oldDelegate.matrix != matrix ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.quietZone != quietZone;
}
