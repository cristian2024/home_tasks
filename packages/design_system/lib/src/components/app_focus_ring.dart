import 'package:flutter/widgets.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_theme_colors.dart';

/// Dónde dibuja [AppFocusRing] su anillo.
enum AppFocusRingPosition {
  /// Alrededor del control. Para los rellenos (botones, chips): por dentro, el
  /// anillo casi no se distinguiría del relleno de un botón primario.
  outside,

  /// Sobre el borde interior. Para lo que va a sangre o dentro de un
  /// contenedor que recorta (filas, opciones de un selector).
  inside,
}

/// Anillo de 2 en `border.focus` que marca el control que tiene el foco del
/// teclado (o de Switch Access). Con el dedo no se dibuja: solo cuando
/// [FocusManager.highlightMode] es [FocusHighlightMode.traditional], como los
/// resaltados de Material.
///
/// Con el constructor por defecto, el anillo aparece cuando [child] o algo
/// dentro de él tiene el foco; sirve para un control con un solo destino de
/// foco (un botón). Con [AppFocusRing.when], lo decide [focused]: para una fila
/// que tiene dentro otros controles con foco propio.
class AppFocusRing extends StatefulWidget {
  const AppFocusRing({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.position = AppFocusRingPosition.outside,
  })  : focused = null,
        keyboardOnly = true;

  const AppFocusRing.when({
    super.key,
    required bool this.focused,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.position = AppFocusRingPosition.inside,
    this.keyboardOnly = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final AppFocusRingPosition position;

  /// Si el control tiene el foco; `null` lo calcula a partir de [child].
  final bool? focused;

  /// Con `false`, el anillo también se dibuja con el dedo. Sirve para marcar
  /// el control activo cuando el foco real debe quedarse en otro sitio (p. ej.
  /// un selector que se abre sin cerrar el teclado de un campo).
  final bool keyboardOnly;

  @override
  State<AppFocusRing> createState() => _AppFocusRingState();
}

class _AppFocusRingState extends State<AppFocusRing> {
  bool _childFocused = false;
  bool _traditional = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    final bool traditional = mode == FocusHighlightMode.traditional;
    if (traditional != _traditional) {
      setState(() => _traditional = traditional);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool? focused = widget.focused;
    final bool visible = (_traditional || !widget.keyboardOnly) && (focused ?? _childFocused);
    final Widget painted = CustomPaint(
      foregroundPainter: visible
          ? _FocusRingPainter(
              color: AppThemeColors.of(context).borderFocus,
              borderRadius: widget.borderRadius,
              position: widget.position,
            )
          : null,
      child: widget.child,
    );
    if (focused != null) {
      return painted;
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (bool hasFocus) => setState(() => _childFocused = hasFocus),
      child: painted,
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({required this.color, required this.borderRadius, required this.position});

  final Color color;
  final BorderRadius borderRadius;
  final AppFocusRingPosition position;

  @override
  void paint(Canvas canvas, Size size) {
    const double halfStroke = AppSizes.strokeThick / 2;
    final Rect bounds = Offset.zero & size;
    final Rect rect = switch (position) {
      AppFocusRingPosition.outside => bounds.inflate(halfStroke),
      AppFocusRingPosition.inside => bounds.deflate(halfStroke),
    };
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.strokeThick;
    canvas.drawRRect(borderRadius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius || oldDelegate.position != position;
}
