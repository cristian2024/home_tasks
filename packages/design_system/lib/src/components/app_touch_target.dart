import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../tokens/app_sizes.dart';

/// Da a [child] un área táctil de al menos [minSize], sin ocupar más sitio ni
/// cambiar su aspecto. Sirve para los controles que se dibujan más pequeños
/// que [AppSizes.minTouchTarget] (p. ej. un botón de 40 de alto): los toques
/// a su alrededor cuentan como suyos, y los lectores de pantalla ven el área
/// entera.
///
/// El padre debe dejar sitio alrededor: lo que caiga fuera de sus límites no
/// llega a [child].
class AppTouchTarget extends SingleChildRenderObjectWidget {
  const AppTouchTarget({super.key, required Widget super.child, this.minSize = AppSizes.minTouchTarget});

  final double minSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTouchTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) =>
      (renderObject as _RenderTouchTarget).minSize = minSize;
}

class _RenderTouchTarget extends RenderProxyBox {
  _RenderTouchTarget(this._minSize);

  double _minSize;

  set minSize(double value) {
    if (value != _minSize) {
      _minSize = value;
      markNeedsSemanticsUpdate();
    }
  }

  Rect get _target => Rect.fromCenter(
        center: size.center(Offset.zero),
        width: math.max(size.width, _minSize),
        height: math.max(size.height, _minSize),
      );

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_target.contains(position)) {
      return false;
    }
    // A child el toque le llega dentro de sus límites.
    final Offset inside = Offset(
      position.dx.clamp(0, math.max(size.width - 1, 0)),
      position.dy.clamp(0, math.max(size.height - 1, 0)),
    );
    if (!hitTestChildren(result, position: inside)) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  Rect get semanticBounds => _target;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}
