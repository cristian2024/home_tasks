import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import '../list/item_list_screen.dart';
import 'move_item_cubit.dart';

/// Elegir el contenedor al que se mueve un objeto. Al terminar hace `pop` con
/// el ID del contenedor.
class MoveItemScreen extends StatelessWidget {
  const MoveItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$move$es moveStrings = itemTrackerStrings.itemTracker.move;
    final MoveItemCubit cubit = context.read<MoveItemCubit>();
    return BlocConsumer<MoveItemCubit, MoveItemState>(
      // El árbol puede volver a emitir después de mover el objeto; el estado
      // sigue en `moved` y no hay que cerrar la pantalla otra vez.
      listenWhen: (MoveItemState previous, MoveItemState current) => previous.status != current.status,
      listener: (BuildContext context, MoveItemState state) {
        final HouseholdItem? destination = state.destination;
        if (state.status == MoveItemStatus.moved && destination != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(moveStrings.moved(name: destination.name))));
          context.pop(destination.id);
        }
      },
      builder: (BuildContext context, MoveItemState state) {
        final HouseholdItem? item = state.item;
        final Object? error = state.error;
        final Map<String, MoveCandidate> candidates = <String, MoveCandidate>{
          for (final MoveCandidate candidate in state.visible) candidate.item.id: candidate,
        };
        return Scaffold(
          appBar: AppTopBar(title: Text(item == null ? itemTrackerStrings.itemTracker.detail.move : moveStrings.title(name: item.name))),
          body: switch (state.status) {
            MoveItemStatus.loading => const AppLoadingView(),
            MoveItemStatus.missing => AppStatusView(
                icon: AppIcons.search,
                title: itemTrackerStrings.itemTracker.detail.missingTitle,
                message: itemTrackerStrings.itemTracker.detail.missingMessage,
              ),
            _ => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                      child: Text(errorMessage(error), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                    child: AppTextField(
                      label: moveStrings.search,
                      prefixIcon: AppIcons.search,
                      textInputAction: TextInputAction.search,
                      onChanged: cubit.search,
                    ),
                  ),
                  if (state.status == MoveItemStatus.moving) const LinearProgressIndicator(),
                  Expanded(
                    child: candidates.isEmpty
                        ? AppStatusView(icon: AppIcons.search, title: moveStrings.empty)
                        : ItemCardList(
                            items: <HouseholdItem>[
                              for (final MoveCandidate candidate in candidates.values) candidate.item,
                            ],
                            semanticLabelBuilder: (HouseholdItem container) => moveStrings.select(name: container.name),
                            subtitleBuilder: (HouseholdItem container) {
                              final MoveCandidate candidate = candidates[container.id]!;
                              return <String>[
                                formatItemPath(candidate.path),
                                switch (candidate.block) {
                                  MoveBlock.current => moveStrings.current,
                                  MoveBlock.tooDeep => moveStrings.tooDeep(max: cubit.maxDepth),
                                  null => '',
                                },
                              ].where((String line) => line.isNotEmpty).join('\n');
                            },
                            enabledBuilder: (HouseholdItem container) => candidates[container.id]!.block == null,
                            onSelected: state.status == MoveItemStatus.moving ? null : cubit.moveTo,
                          ),
                  ),
                ],
              ),
          },
        );
      },
    );
  }
}
