import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';

/// Marco para la vista previa de una cámara: panel oscuro con esquinas
/// redondeadas y, encima de [child], la guía de dónde poner el código.
class AppCameraFrame extends StatelessWidget {
  const AppCameraFrame({super.key, required this.child});

  /// Lado de la guía.
  static const double guideSize = 220.0;

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.large),
        child: ColoredBox(
          color: AppColors.neutral950,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              child,
              const IgnorePointer(
                child: Center(child: CustomPaint(size: Size.square(guideSize), painter: _GuidePainter())),
              ),
            ],
          ),
        ),
      );
}

/// Las cuatro esquinas de la guía.
class _GuidePainter extends CustomPainter {
  const _GuidePainter();

  /// Lado del dibujo original de las esquinas.
  static const double _gridSize = 24.0;
  static const double _strokeWidth = 5.5;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / _gridSize;
    final Paint paint = Paint()
      ..color = AppColors.neutral0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _strokeWidth / scale;
    canvas.scale(scale);
    for (int turn = 0; turn < 4; turn++) {
      canvas.drawPath(
        Path()
          ..moveTo(3, 7)
          ..lineTo(3, 5)
          ..arcToPoint(const Offset(5, 3), radius: const Radius.circular(2))
          ..lineTo(7, 3),
        paint,
      );
      canvas
        ..translate(_gridSize, 0)
        ..rotate(1.5707963267948966);
    }
  }

  @override
  bool shouldRepaint(_GuidePainter oldDelegate) => false;
}
