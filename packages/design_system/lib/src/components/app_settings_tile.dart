import 'package:flutter/material.dart';

import '../tokens/app_icons.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_theme_colors.dart';
import 'app_focus_ring.dart';

/// Fila de ajustes: abre otra pantalla o ejecuta una acción con [onTap].
///
/// Con [enabled] en `false` se muestra atenuada y no responde (p. ej. una
/// función que llegará más adelante, explicada en [subtitle]). Sin [trailing]
/// y con [onTap] muestra una flecha. Con [destructive], el icono y el texto van
/// en rojo y no hay flecha (p. ej. «Salir del hogar»). Con el foco del teclado,
/// la fila lleva el anillo por dentro; un [trailing] con foco propio lleva el
/// suyo.
class AppSettingsTile extends StatefulWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.enabled = true,
    this.destructive = false,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;
  final bool destructive;

  /// Texto más pequeño, para filas de consulta (p. ej. un historial).
  final bool compact;

  @override
  State<AppSettingsTile> createState() => _AppSettingsTileState();
}

class _AppSettingsTileState extends State<AppSettingsTile> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'AppSettingsTile');

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final String? subtitle = widget.subtitle;
    final bool enabled = widget.enabled;
    final bool destructive = widget.destructive;
    final bool compact = widget.compact;
    final VoidCallback? onTap = widget.onTap;
    final bool interactive = enabled && onTap != null;
    final AppThemeColors colors = AppThemeColors.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? subtitleStyle = switch ((compact, enabled)) {
      (true, _) => textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      (false, false) => textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
      (false, true) => null,
    };
    // ListTile solo respeta un color propio en una fila desactivada si es un
    // `WidgetStateColor`.
    final Color? foreground = switch ((enabled, destructive)) {
      (false, _) => WidgetStateColor.resolveWith((Set<WidgetState> _) => colors.textDisabled),
      (true, true) => colors.textDanger,
      (true, false) => null,
    };
    return AppFocusRing.when(
      focused: _focusNode.hasPrimaryFocus,
      child: ListTile(
        focusNode: _focusNode,
        enabled: enabled,
        iconColor: foreground,
        textColor: foreground,
        leading: Icon(widget.icon),
        title: Text(widget.title, style: compact ? textTheme.bodyMedium : null),
        // Atenuada, la explicación de por qué no responde debe seguir legible.
        subtitle: subtitle == null ? null : Text(subtitle, style: subtitleStyle),
        trailing: widget.trailing ??
            (interactive && !destructive
                ? Icon(AppIcons.chevronRight, size: AppSizes.iconCompact, color: colors.textTertiary)
                : null),
        onTap: interactive ? onTap : null,
      ),
    );
  }
}
