import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_bottom_sheet.dart';

/// Una acción de [showAppActionSheet].
class AppSheetAction<T> {
  const AppSheetAction({required this.value, required this.label, required this.icon, this.destructive = false});

  final T value;
  final String label;
  final IconData icon;

  /// En rojo, para lo que borra o no se puede deshacer.
  final bool destructive;
}

/// Abre una hoja inferior con [actions] agrupadas, al alcance del pulgar (p. ej.
/// el menú ⋮ de una pantalla). Devuelve el valor de la elegida, o `null` si se
/// cierra sin elegir. [label] nombra la hoja para los lectores de pantalla.
Future<T?> showAppActionSheet<T>(
  BuildContext context, {
  required String label,
  required List<AppSheetAction<T>> actions,
}) =>
    showAppBottomSheet<T>(
      context,
      builder: (BuildContext context) => Semantics(
        label: label,
        namesRoute: true,
        explicitChildNodes: true,
        child: _ActionGroup<T>(actions: actions),
      ),
    );

class _ActionGroup<T> extends StatelessWidget {
  const _ActionGroup({required this.actions});

  final List<AppSheetAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    return Material(
      color: colors.bgSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (int index, AppSheetAction<T> action) in actions.indexed) ...<Widget>[
            if (index > 0) const Divider(height: AppSizes.strokeThin),
            _ActionRow<T>(action: action),
          ],
        ],
      ),
    );
  }
}

class _ActionRow<T> extends StatelessWidget {
  const _ActionRow({required this.action});

  /// Alto mínimo de cada fila.
  static const double minHeight = 56.0;

  final AppSheetAction<T> action;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    final Color foreground = action.destructive ? colors.textDanger : colors.textPrimary;
    return InkWell(
      onTap: () => Navigator.of(context).pop(action.value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.s300, AppSpacing.s300, AppSpacing.s300),
          child: Row(
            spacing: AppSpacing.s300,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(action.icon, color: action.destructive ? colors.textDanger : colors.textSecondary),
              ),
              Expanded(
                child: Text(action.label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: foreground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
