import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_theme_colors.dart';

/// Fila de ajustes: abre otra pantalla o ejecuta una acción con [onTap].
///
/// Con [enabled] en `false` se muestra atenuada y no responde (p. ej. una
/// función que llegará más adelante, explicada en [subtitle]). Sin [trailing]
/// y con [onTap] muestra una flecha. Con [destructive], el icono y el texto van
/// en rojo y no hay flecha (p. ej. «Salir del hogar»).
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.enabled = true,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    final bool interactive = enabled && onTap != null;
    final AppThemeColors colors = AppThemeColors.of(context);
    // ListTile solo respeta un color propio en una fila desactivada si es un
    // `WidgetStateColor`.
    final Color? foreground = switch ((enabled, destructive)) {
      (false, _) => WidgetStateColor.resolveWith((Set<WidgetState> _) => colors.textDisabled),
      (true, true) => colors.textDanger,
      (true, false) => null,
    };
    return ListTile(
      enabled: enabled,
      iconColor: foreground,
      textColor: foreground,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing ??
          (interactive && !destructive
              ? Icon(Icons.chevron_right, size: AppSizes.iconCompact, color: colors.textTertiary)
              : null),
      onTap: interactive ? onTap : null,
    );
  }
}
