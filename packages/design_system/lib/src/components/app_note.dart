import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';

/// Nota destacada con un icono: un dato que acompaña a la pantalla (p. ej. qué
/// identificador se va a asociar).
class AppNote extends StatelessWidget {
  const AppNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.bgBrandSubtle, borderRadius: BorderRadius.circular(AppRadii.small)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s300),
        child: Row(
          spacing: AppSpacing.s300,
          children: <Widget>[
            ExcludeSemantics(child: Icon(icon, size: AppSizes.iconCompact, color: colors.textBrand)),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
