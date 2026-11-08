import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Tarjeta del sistema de diseño. Con [onTap] es un único control para los
/// lectores de pantalla: se anuncia con [semanticLabel] si se indica y, si no,
/// con los textos que contiene.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);
    final VoidCallback? onTap = this.onTap;
    final String? semanticLabel = this.semanticLabel;
    final Widget card = Card(
      // El nodo lo pone la tarjeta: así la etiqueta y la pulsación van juntas.
      semanticContainer: false,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    if (onTap == null) {
      return Semantics(label: semanticLabel, container: true, child: card);
    }
    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        container: true,
        onTap: onTap,
        excludeSemantics: true,
        child: card,
      );
    }
    return MergeSemantics(child: Semantics(button: true, child: card));
  }
}
