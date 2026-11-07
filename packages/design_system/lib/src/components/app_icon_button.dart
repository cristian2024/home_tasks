import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_theme_colors.dart';

enum AppIconButtonVariant {
  /// Acción de la barra superior.
  standard,

  /// Acción secundaria dentro de una fila: más pequeña y discreta.
  subtle,
  filled,
  tonal,

  /// Acción principal junto a un campo: rectangular, del alto del campo.
  primary,
}

/// Botón de icono. El [tooltip] es obligatorio: también es la etiqueta que
/// leen TalkBack / VoiceOver (spec §14.1).
class AppIconButton extends StatelessWidget {

  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;

  static const double _primaryWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    return switch (variant) {
      AppIconButtonVariant.standard => IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            foregroundColor: colors.textPrimary,
            disabledForegroundColor: colors.textDisabled,
          ),
          onPressed: onPressed,
        ),
      AppIconButtonVariant.subtle => IconButton(
          tooltip: tooltip,
          icon: Icon(icon, size: AppSizes.iconCompact),
          style: IconButton.styleFrom(
            foregroundColor: colors.textSecondary,
            disabledForegroundColor: colors.textDisabled,
          ),
          onPressed: onPressed,
        ),
      AppIconButtonVariant.filled => IconButton.filled(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed),
      AppIconButtonVariant.tonal => IconButton.filledTonal(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed),
      AppIconButtonVariant.primary => IconButton.filled(
          tooltip: tooltip,
          icon: Icon(icon, size: AppSizes.iconCompact),
          style: IconButton.styleFrom(
            minimumSize: const Size(_primaryWidth, AppSizes.controlLarge),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.small)),
          ),
          onPressed: onPressed,
        ),
    };
  }
}
