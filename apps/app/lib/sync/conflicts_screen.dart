import 'package:core_sync/core_sync.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../i18n/strings.g.dart';
import 'conflict_description.dart';
import 'conflicts_cubit.dart';

/// Bandeja de conflictos: cada uno con la resolución que ya rige y las demás
/// opciones. La elegida se sincroniza con los demás dispositivos.
class ConflictsScreen extends StatelessWidget {
  const ConflictsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$conflicts$es t = appStrings.app.sync.conflicts;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocBuilder<ConflictsCubit, ConflictsState>(
        builder: (BuildContext context, ConflictsState state) {
          if (!state.loaded) {
            return const AppLoadingView();
          }
          if (state.conflicts.isEmpty) {
            return AppStatusView(icon: Icons.check_circle_outline, title: t.emptyTitle, message: t.emptyMessage);
          }
          final ConflictsCubit cubit = context.read<ConflictsCubit>();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              if (state.conflicts.length > 1) ...<Widget>[
                AppButton(
                  label: t.resolveAll,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  isLoading: state.resolving.isNotEmpty,
                  onPressed: cubit.keepAll,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              for (final SyncConflict conflict in state.conflicts)
                _ConflictItem(
                  key: ValueKey<String>(conflict.id),
                  conflict: conflict,
                  itemNames: state.itemNames,
                  busy: state.resolving.contains(conflict.id),
                  onResolve: (String optionId) => cubit.resolve(conflict, optionId),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ConflictItem extends StatelessWidget {
  const _ConflictItem({
    super.key,
    required this.conflict,
    required this.itemNames,
    required this.busy,
    required this.onResolve,
  });

  final SyncConflict conflict;
  final Map<String, String> itemNames;
  final bool busy;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    final ConflictDescription description = ConflictDescription.of(conflict, itemNames);
    final AppTranslations$app$sync$conflicts$es t = appStrings.app.sync.conflicts;
    final bool single = conflict.options.length == 1;
    return AppConflictCard<String>(
      title: description.title,
      message: description.message,
      // Con una sola opción (p. ej. un movimiento deshecho) solo se confirma.
      options: <AppConflictOption<String>>[
        if (!single)
          for (final ConflictOption option in conflict.options)
            AppConflictOption<String>(value: option.id, label: description.labelOf(option.id)),
      ],
      applied: conflict.provisionalOptionId,
      appliedLabel: t.applied,
      onSelected: onResolve,
      keepLabel: single ? description.labelOf(conflict.provisionalOptionId) : t.keepCurrent,
      onKeep: () => onResolve(conflict.provisionalOptionId),
      busy: busy,
    );
  }
}
