import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

/// Título de sección, marcado como encabezado para la navegación por
/// encabezados de TalkBack / VoiceOver.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.title, {super.key, this.trailing, this.compact = false});

  final String title;
  final Widget? trailing;

  /// Sin alto mínimo: para separar grupos dentro de una lista de filas, que ya
  /// tienen su propio margen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs, bottom: compact ? AppSpacing.s0 : AppSpacing.s150),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? AppSpacing.s0 : AppSizes.controlSmall),
        // Con texto grande, la acción pasa debajo del título en lugar de
        // estrecharlo hasta partir las palabras.
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
