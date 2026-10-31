import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import 'app_badge.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Una forma de resolver el conflicto de un [AppConflictCard].
class AppConflictOption<T> {
  const AppConflictOption({required this.value, required this.label, this.description});

  final T value;
  final String label;

  /// Qué pasará si se elige (p. ej. «La etiqueta queda en "Caja A"»).
  final String? description;
}

/// Tarjeta de un conflicto entre dispositivos: qué pasó ([title], [message])
/// y las opciones para resolverlo.
///
/// La opción [applied] es la que ya rige mientras nadie elige; se marca con
/// [appliedLabel] (p. ej. «Aplicada ahora»). Tocar una opción llama a
/// [onSelected] con su valor; [keepLabel] y [onKeep] (p. ej. «Dejarlo así»)
/// confirman la aplicada. Con [busy], las acciones no responden.
class AppConflictCard<T> extends StatelessWidget {
  const AppConflictCard({
    super.key,
    required this.title,
    required this.message,
    required this.options,
    required this.applied,
    required this.appliedLabel,
    required this.onSelected,
    this.keepLabel,
    this.onKeep,
    this.busy = false,
  });

  final String title;
  final String message;
  final List<AppConflictOption<T>> options;
  final T applied;
  final String appliedLabel;
  final ValueChanged<T> onSelected;
  final String? keepLabel;
  final VoidCallback? onKeep;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final AppConflictOption<T> option in options)
            _ConflictOptionTile(
              label: option.label,
              description: option.description,
              appliedLabel: option.value == applied ? appliedLabel : null,
              onTap: busy ? null : () => onSelected(option.value),
            ),
          if (keepLabel case final String keepLabel) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            AppButton(label: keepLabel, isLoading: busy, onPressed: onKeep),
          ],
        ],
      ),
    );
  }
}

class _ConflictOptionTile extends StatelessWidget {
  const _ConflictOptionTile({required this.label, required this.description, required this.appliedLabel, required this.onTap});

  final String label;
  final String? description;
  final String? appliedLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: AppSizes.minTouchTarget,
      enabled: onTap != null,
      leading: Icon(appliedLabel == null ? Icons.radio_button_unchecked : Icons.radio_button_checked),
      title: Text(label),
      subtitle: description == null && appliedLabel == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (description case final String description) Text(description),
                if (appliedLabel case final String appliedLabel) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  AppBadge(label: appliedLabel, icon: Icons.check),
                ],
              ],
            ),
      onTap: onTap,
    );
  }
}
