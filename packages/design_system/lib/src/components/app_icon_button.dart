import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_theme_colors.dart';
import 'app_focus_ring.dart';

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
/// leen TalkBack / VoiceOver (spec §14.1). Con el foco del teclado lleva un
/// anillo por fuera ([AppFocusRing]).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;

  /// Color del icono en [AppIconButtonVariant.standard] y
  /// [AppIconButtonVariant.subtle], si no es el de la variante (p. ej.
  /// `textTertiary` para una acción que no debe competir con el contenido).
  final Color? iconColor;

  static const double _primaryWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    final Widget button = switch (variant) {
      AppIconButtonVariant.standard => IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            foregroundColor: iconColor ?? colors.textPrimary,
            disabledForegroundColor: colors.textDisabled,
          ),
          onPressed: onPressed,
        ),
      AppIconButtonVariant.subtle => IconButton(
          tooltip: tooltip,
          icon: Icon(icon, size: AppSizes.iconCompact),
          style: IconButton.styleFrom(
            foregroundColor: iconColor ?? colors.textSecondary,
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
    final double radius = variant == AppIconButtonVariant.primary ? AppRadii.small : AppRadii.full;
    return AppFocusRing(borderRadius: BorderRadius.circular(radius), child: button);
  }
}
