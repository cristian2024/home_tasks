import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Situación que muestra un [AppSyncStatusCard]. Elige el icono y el color.
enum AppSyncTone {
  /// Sin configurar o detenida.
  off,

  /// Al día y atenta a los demás.
  idle,

  /// Sincronizando ahora.
  syncing,

  /// La última vez falló.
  error,
}

/// Tarjeta con el estado de una sincronización: [title] (p. ej. «Sincronizado
/// hace 5 min»), [details] en líneas (cambios pendientes, dispositivos a la
/// vista), un [message] opcional que explica el error y una acción (p. ej.
/// «Sincronizar ahora»).
///
/// El título se anuncia a los lectores de pantalla cada vez que cambia.
/// Mientras [tone] es [AppSyncTone.syncing], la acción muestra un indicador y
/// no responde.
class AppSyncStatusCard extends StatelessWidget {
  const AppSyncStatusCard({
    super.key,
    required this.tone,
    required this.title,
    this.details = const <String>[],
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final AppSyncTone tone;
  final String title;
  final List<String> details;
  final String? message;

  /// Texto de la acción. Sin él, no hay botón.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeColors colors = AppThemeColors.of(context);
    final TextStyle? bodyStyle = theme.textTheme.bodyMedium;
    final String? message = this.message;
    final String? actionLabel = this.actionLabel;
    final (IconData icon, Color color) = switch (tone) {
      AppSyncTone.off => (Icons.home_outlined, colors.textSecondary),
      AppSyncTone.idle => (Icons.sync, colors.textBrand),
      AppSyncTone.syncing => (Icons.sync, colors.textBrand),
      AppSyncTone.error => (Icons.sync_problem, colors.textDanger),
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ExcludeSemantics(child: Icon(icon, color: color)),
              const SizedBox(width: AppSpacing.s300),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) const SizedBox(height: AppSpacing.s300),
          for (final String detail in details) Text(detail, style: bodyStyle?.copyWith(color: colors.textSecondary)),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s300),
            Text(message, style: bodyStyle?.copyWith(color: tone == AppSyncTone.error ? colors.textDanger : null)),
          ],
          if (actionLabel != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s300),
            AppButton(
              label: actionLabel,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.medium,
              expand: true,
              isLoading: tone == AppSyncTone.syncing,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
