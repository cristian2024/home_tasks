import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_card.dart';
import 'app_icon_box.dart';

/// Tarjeta de un módulo en la pantalla de inicio: icono, [title], un [summary]
/// corto con sus [badges] y, debajo, sus [actions] (normalmente [AppButton]) a
/// partes iguales.
///
/// Con [onTap], toda la tarjeta es un botón que se anuncia con [title]. No
/// combinarlo con [actions].
class AppModuleCard extends StatelessWidget {
  const AppModuleCard({
    super.key,
    required this.icon,
    required this.title,
    this.summary,
    this.badges = const <Widget>[],
    this.actions = const <Widget>[],
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? summary;
  final List<Widget> badges;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppThemeColors colors = AppThemeColors.of(context);
    final String? summary = this.summary;
    return AppCard(
      semanticLabel: onTap == null ? null : title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIconBox(icon: icon),
              const SizedBox(width: AppSpacing.s300),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(header: true, child: Text(title, style: textTheme.titleLarge)),
                    if (summary != null || badges.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          if (summary != null)
                            Text(summary, style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                          ...badges,
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Row(
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (final Widget action in actions) Expanded(child: action),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
