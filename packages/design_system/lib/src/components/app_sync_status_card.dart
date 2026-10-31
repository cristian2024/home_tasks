import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
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
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? bodyStyle = theme.textTheme.bodyMedium;
    final (IconData icon, Color color) = switch (tone) {
      AppSyncTone.off => (Icons.sync_disabled, colors.onSurfaceVariant),
      AppSyncTone.idle => (Icons.sync, colors.primary),
      AppSyncTone.syncing => (Icons.sync, colors.primary),
      AppSyncTone.error => (Icons.sync_problem, colors.error),
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ExcludeSemantics(child: Icon(icon, color: color)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          for (final String detail in details) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(detail, style: bodyStyle?.copyWith(color: colors.onSurfaceVariant)),
          ],
          if (message case final String message) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: bodyStyle?.copyWith(color: tone == AppSyncTone.error ? colors.error : null)),
          ],
          if (actionLabel case final String actionLabel) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: actionLabel,
              icon: Icons.sync,
              variant: AppButtonVariant.secondary,
              isLoading: tone == AppSyncTone.syncing,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
