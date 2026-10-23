import 'package:flutter/material.dart';

/// Fila de ajustes: abre otra pantalla o ejecuta una acción con [onTap].
///
/// Con [enabled] en `false` se muestra atenuada y no responde (p. ej. una
/// función que llegará más adelante, explicada en [subtitle]). Sin [trailing]
/// y con [onTap] muestra una flecha.
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    final bool interactive = enabled && onTap != null;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing ?? (interactive ? const Icon(Icons.chevron_right) : null),
      onTap: interactive ? onTap : null,
    );
  }
}
