import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'field_error.dart';

/// Campo de texto con etiqueta obligatoria, visible encima del campo y leída
/// por los lectores de pantalla.
///
/// Con [maxLength], el contador aparece solo al acercarse al límite
/// ([counterThreshold]), con el texto de [counterText] («84 de 100»). Con más
/// de una línea, el campo empieza con [minLines] (por defecto
/// [multilineMinLines]) y crece hasta [maxLines].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.counterText,
    this.enabled = true,
    this.autofocus = false,
  });

  /// Parte de [maxLength] a partir de la cual se muestra el contador.
  static const double counterThreshold = 0.8;
  static const int multilineMinLines = 2;

  final String label;
  final TextEditingController? controller;

  /// Para llevar el foco al campo, p. ej. al campo con error al guardar.
  final FocusNode? focusNode;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;

  /// Líneas con las que empieza un campo de varias líneas. Con `1`, el campo
  /// mide como uno de una línea y crece al escribir.
  final int? minLines;
  final int? maxLength;

  /// Texto del contador a partir de lo escrito y el máximo. Sin él, `84/100`.
  final String Function(int current, int max)? counterText;
  final bool enabled;
  final bool autofocus;

  bool get _multiline => maxLines != 1;

  int? get _minLines => _multiline ? minLines ?? multilineMinLines : null;

  Widget? _counter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (maxLength == null || currentLength < maxLength * counterThreshold) {
      return null;
    }
    final String Function(int current, int max)? counterText = this.counterText;
    return Text(counterText == null ? '$currentLength/$maxLength' : counterText(currentLength, maxLength));
  }

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
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            minLines: _minLines,
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
                vertical: (_minLines ?? 1) > 1 ? AppSpacing.md : AppSpacing.s300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
