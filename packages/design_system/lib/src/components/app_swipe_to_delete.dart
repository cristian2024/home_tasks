import 'package:flutter/material.dart';

import '../tokens/app_elevation.dart';
import '../tokens/app_icons.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';

/// Fila que se borra deslizándola a la izquierda. Debajo aparece la zona
/// [label], de [revealWidth] de ancho, sobre el fondo de peligro; mientras se
/// mueve, la fila lleva una sombra para leerse como algo que se arrastra. Al
/// soltarla con la zona entera a la vista (o con un gesto rápido) sale de la
/// pantalla y llama a [onDelete]; con menos, vuelve a su sitio.
///
/// No pide confirmación: quien la usa ofrece «Deshacer» y quita la fila de la
/// lista. El gesto no es la única vía, así que no se anuncia: la acción de
/// borrar debe estar también en la fila (p. ej. con
/// `AppCheckTile.semanticActions`) o en otra pantalla.
class AppSwipeToDelete extends StatefulWidget {
  const AppSwipeToDelete({
    super.key,
    required this.label,
    required this.onDelete,
    required this.child,
    this.enabled = true,
  });

  /// Ancho de la zona de borrar: soltar con ella entera a la vista borra.
  static const double revealWidth = 120.0;

  /// Velocidad (en puntos por segundo) a partir de la que un gesto rápido
  /// borra aunque no se vea toda la zona.
  static const double flingVelocity = 1000.0;

  static const Duration _settleDuration = Duration(milliseconds: 200);

  final String label;
  final VoidCallback onDelete;
  final Widget child;
  final bool enabled;

  @override
  State<AppSwipeToDelete> createState() => _AppSwipeToDeleteState();
}

class _AppSwipeToDeleteState extends State<AppSwipeToDelete> with SingleTickerProviderStateMixin {
  /// Cuánto se ha desplazado la fila, como fracción de su ancho.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppSwipeToDelete._settleDuration,
  );
  double _width = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_width == 0) {
      return;
    }
    _controller.value -= details.primaryDelta! / _width;
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final double velocity = details.primaryVelocity ?? 0;
    final bool revealed = _controller.value * _width >= AppSwipeToDelete.revealWidth;
    if (revealed || velocity <= -AppSwipeToDelete.flingVelocity) {
      await _controller.animateTo(1);
      if (mounted) {
        widget.onDelete();
      }
    } else {
      await _controller.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeColors colors = AppThemeColors.of(context);
    final List<BoxShadow> shadow = theme.brightness == Brightness.dark ? AppElevation.dark3 : AppElevation.light3;
    final bool enabled = widget.enabled;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _width = constraints.maxWidth;
        return GestureDetector(
          excludeFromSemantics: true,
          onHorizontalDragUpdate: enabled ? _onDragUpdate : null,
          onHorizontalDragEnd: enabled ? _onDragEnd : null,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? zone) =>
                      _controller.value == 0 ? const SizedBox.shrink() : zone!,
                  child: ExcludeSemantics(
                    child: ColoredBox(
                      color: colors.actionDangerDefault,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: AppSwipeToDelete.revealWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: AppSpacing.sm,
                            children: <Widget>[
                              Icon(AppIcons.trash, size: AppSizes.iconCompact, color: colors.textOnDanger),
                              Flexible(
                                child: Text(
                                  widget.label,
                                  style: theme.textTheme.labelLarge?.copyWith(color: colors.textOnDanger),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? row) {
                  final double value = _controller.value;
                  return Transform.translate(
                    offset: Offset(-value * _width, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(boxShadow: value == 0 ? null : shadow),
                      child: row,
                    ),
                  );
                },
                child: Material(color: colors.bgCanvas, child: widget.child),
              ),
            ],
          ),
        );
      },
    );
  }
}
