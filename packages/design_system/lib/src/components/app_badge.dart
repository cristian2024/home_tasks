import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';

/// Importancia de un [AppBadge].
enum AppBadgeTone {
  /// Lo más importante (p. ej. urgente o atrasado).
  critical,

  /// Requiere atención pronto.
  warning,

  /// Información sin urgencia (p. ej. una categoría).
  neutral,
}

/// Etiqueta corta para ver de un vistazo un estado o una clasificación. Los
/// colores salen del tema, con contraste suficiente en claro y en oscuro.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone = AppBadgeTone.neutral, this.icon});

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final (Color background, Color foreground) = switch (tone) {
      AppBadgeTone.critical => (colors.errorContainer, colors.onErrorContainer),
      AppBadgeTone.warning => (colors.tertiaryContainer, colors.onTertiaryContainer),
      AppBadgeTone.neutral => (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };
    final IconData? icon = this.icon;
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.small)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              ExcludeSemantics(child: Icon(icon, size: 16, color: foreground)),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: foreground))),
          ],
        ),
      ),
    );
  }
}
