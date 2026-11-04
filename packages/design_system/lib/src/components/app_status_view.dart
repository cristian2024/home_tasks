import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';

/// Estado vacío, de error o informativo a pantalla completa. Hace scroll para
/// no desbordarse con el texto al 200 %.
class AppStatusView extends StatelessWidget {
  const AppStatusView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Diámetro del círculo del icono.
  static const double iconCircleSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final AppThemeColors colors = AppThemeColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExcludeSemantics(
              child: Container(
                width: iconCircleSize,
                height: iconCircleSize,
                decoration: BoxDecoration(color: colors.bgBrandSubtle, shape: BoxShape.circle),
                child: Icon(icon, size: AppSizes.iconMedium, color: colors.textBrand),
              ),
            ),
            const SizedBox(height: AppSpacing.s300),
            Semantics(
              header: true,
              child: Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s300),
              Text(
                message!,
                style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...<Widget>[const SizedBox(height: AppSpacing.s300), action!],
          ],
        ),
      ),
    );
  }
}
