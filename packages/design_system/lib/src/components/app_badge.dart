import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';

/// Importancia de un [AppBadge].
enum AppBadgeTone {
  /// Lo más importante (p. ej. urgente o atrasado).
  critical,

  /// Requiere atención pronto.
  warning,

  /// Información sin urgencia (p. ej. una categoría).
  neutral,

  /// Un dato destacado, sin ser un aviso.
  brand,

  /// Algo que está bien (p. ej. un módulo activo).
  success,
}

/// Etiqueta corta para ver de un vistazo un estado o una clasificación. Los
/// colores salen del tema, con contraste suficiente en claro y en oscuro.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone = AppBadgeTone.neutral, this.icon});

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.s50);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeColors colors = AppThemeColors.of(context);
    final (Color background, Color foreground, Color? border) = switch (tone) {
      AppBadgeTone.critical => (colors.bgDangerSubtle, colors.textDanger, colors.borderBadgeDanger),
      AppBadgeTone.warning => (colors.bgWarningSubtle, colors.textWarning, colors.borderBadgeWarning),
      AppBadgeTone.neutral => (colors.bgBadgeNeutral, colors.textSecondary, null),
      AppBadgeTone.brand => (colors.bgBrandSubtle, colors.textBrand, null),
      AppBadgeTone.success => (colors.bgSuccessSubtle, colors.textSuccess, null),
    };
    final IconData? icon = this.icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: border == null ? null : Border.all(color: border, width: AppSizes.strokeThin),
      ),
      child: Padding(
        padding: _padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              ExcludeSemantics(child: Icon(icon, size: AppSizes.iconSmall, color: foreground)),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: foreground))),
          ],
        ),
      ),
    );
  }
}
