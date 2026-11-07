import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'field_error.dart';

/// Campo de texto con etiqueta obligatoria, visible encima del campo y leída
/// por los lectores de pantalla.
///
/// Con [maxLength], el contador aparece solo al acercarse al límite
/// ([counterThreshold]). Con más de una línea, el campo empieza con
/// [multilineMinLines] y crece hasta [maxLines].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
  });

  /// Parte de [maxLength] a partir de la cual se muestra el contador.
  static const double counterThreshold = 0.8;
  static const int multilineMinLines = 2;

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;

  bool get _multiline => maxLines != 1;

  Widget? _counter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) =>
      maxLength == null || currentLength < maxLength * counterThreshold ? null : Text('$currentLength/$maxLength');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeColors colors = AppThemeColors.of(context);
    final IconData? prefixIcon = this.prefixIcon;
    final String? errorText = this.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: colors.textPrimary))),
        const SizedBox(height: AppSpacing.s150),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            minLines: _multiline ? multilineMinLines : null,
            maxLines: maxLines,
            maxLength: maxLength,
            buildCounter: _counter,
            enabled: enabled,
            autofocus: autofocus,
            decoration: InputDecoration(
              hintText: hint,
              error: errorText == null ? null : FieldError(errorText),
              helperText: helperText,
              helperMaxLines: 3,
              errorMaxLines: 3,
              prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: colors.textTertiary),
              prefixIconConstraints: const BoxConstraints(minWidth: AppSizes.minTouchTarget),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s300,
                vertical: _multiline ? AppSpacing.md : AppSpacing.s300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
