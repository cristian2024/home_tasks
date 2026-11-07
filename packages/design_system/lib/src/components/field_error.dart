import 'package:flutter/material.dart';

import '../tokens/app_icons.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';

/// Error bajo un campo: icono y texto, para no depender solo del rojo. Lo usan
/// [AppTextField] y [AppPickerField]; no se exporta.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: <Widget>[
        ExcludeSemantics(child: Icon(AppIcons.circleAlert, size: AppSizes.iconSmall, color: colors.textDanger)),
        Flexible(child: Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textDanger))),
      ],
    );
  }
}
