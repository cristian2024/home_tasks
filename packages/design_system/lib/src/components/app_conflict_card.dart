import 'package:flutter/material.dart';

import '../tokens/app_icons.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
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
    final String? keepLabel = this.keepLabel;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s300),
          Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          for (final AppConflictOption<T> option in options) ...<Widget>[
            const SizedBox(height: AppSpacing.s300),
            if (option.value == applied)
              _AppliedOption(
                label: option.label,
                description: option.description,
                appliedLabel: appliedLabel,
                onTap: busy ? null : () => onSelected(option.value),
              )
            else
              _OtherOption(
                label: option.label,
                description: option.description,
                onTap: busy ? null : () => onSelected(option.value),
              ),
          ],
          if (keepLabel != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s300),
            AppButton(label: keepLabel, size: AppButtonSize.medium, isLoading: busy, onPressed: onKeep, expand: true),
          ],
        ],
      ),
    );
  }
}

/// La opción que ya rige: fila de marca con su etiqueta. Sigue siendo pulsable.
class _AppliedOption extends StatelessWidget {
  const _AppliedOption({
    required this.label,
    required this.description,
    required this.appliedLabel,
    required this.onTap,
  });

  final String label;
  final String? description;
  final String appliedLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppThemeColors colors = AppThemeColors.of(context);
    final String? description = this.description;
    return MergeSemantics(
      child: Material(
        color: colors.bgBrandSubtle,
        borderRadius: BorderRadius.circular(AppRadii.small),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s300),
              child: Row(
                children: <Widget>[
                  ExcludeSemantics(child: Icon(AppIcons.check, size: AppSizes.iconCompact, color: colors.textBrand)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(label, style: textTheme.labelLarge?.copyWith(color: colors.textPrimary)),
                            if (description != null)
                              Text(description, style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                        AppBadge(label: appliedLabel, tone: AppBadgeTone.brand),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtherOption extends StatelessWidget {
  const _OtherOption({required this.label, required this.description, required this.onTap});

  final String label;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? description = this.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(label: label, variant: AppButtonVariant.outline, size: AppButtonSize.medium, expand: true, onPressed: onTap),
        if (description != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}
