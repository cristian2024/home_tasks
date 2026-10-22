import 'package:flutter/material.dart';

enum AppIconButtonVariant { standard, filled, tonal }

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

  @override
  Widget build(BuildContext context) => switch (variant) {
        AppIconButtonVariant.standard => IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed),
        AppIconButtonVariant.filled => IconButton.filled(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed),
        AppIconButtonVariant.tonal =>
          IconButton.filledTonal(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed),
      };
}
