import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'field_error.dart';

/// Campo que no se escribe: muestra [value] y, al tocarlo, abre un selector
/// (p. ej. una fecha). Se ve como [AppTextField], con la etiqueta encima.
///
/// Sin [value] muestra [placeholder]. Los lectores de pantalla lo anuncian como
/// un botón con su etiqueta, su valor y [semanticHint] (p. ej. «Cambiar»).
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.value,
    this.errorText,
    this.semanticHint,
  });

  final String label;
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback? onTap;
  final String? errorText;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeColors colors = AppThemeColors.of(context);
    final String? value = this.value;
    final String? errorText = this.errorText;
    final BorderRadius radius = BorderRadius.circular(AppRadii.small);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: colors.textPrimary))),
        const SizedBox(height: AppSpacing.s150),
        Semantics(
          button: true,
          label: label,
          value: value ?? placeholder,
          hint: semanticHint,
          enabled: onTap != null,
          onTap: onTap,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: InputDecorator(
              isEmpty: false,
              decoration: InputDecoration(
                error: errorText == null ? null : FieldError(errorText),
                errorMaxLines: 3,
                enabled: onTap != null,
                suffixIcon: Icon(icon, color: colors.textSecondary),
                suffixIconConstraints: const BoxConstraints(minWidth: AppSizes.minTouchTarget),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s300, vertical: AppSpacing.s300),
              ),
              child: Text(
                value ?? placeholder,
                style: theme.textTheme.bodyLarge?.copyWith(color: value == null ? colors.textSecondary : colors.textPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
