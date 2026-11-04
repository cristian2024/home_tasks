import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_theme_colors.dart';

/// Icono dentro de un recuadro de marca, o de error con [error]. Es decorativo:
/// quien lo usa da el nombre a los lectores de pantalla.
class AppIconBox extends StatelessWidget {
  const AppIconBox({super.key, required this.icon, this.error = false});

  /// Lado del recuadro.
  static const double size = 56.0;

  final IconData icon;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: error ? colors.bgDangerSubtle : colors.bgBrandSubtle,
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        child: Icon(icon, size: AppSizes.iconMedium, color: error ? colors.textDanger : colors.textBrand),
      ),
    );
  }
}
