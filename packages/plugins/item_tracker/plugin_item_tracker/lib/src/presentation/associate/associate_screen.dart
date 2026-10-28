import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import '../list/item_list_screen.dart';
import 'associate_cubit.dart';

/// Elegir el objeto al que se asocia el identificador. Al terminar hace
/// `pop` con el ID del objeto.
class AssociateScreen extends StatelessWidget {
  const AssociateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$associate$es t = itemTrackerStrings.itemTracker.associate;
    final AssociateCubit cubit = context.read<AssociateCubit>();
    final ({String rawValue, IdentifierType type}) identifier = cubit.identifier;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocConsumer<AssociateCubit, AssociateState>(
        listener: (BuildContext context, AssociateState state) {
          final HouseholdItem? boundItem = state.boundItem;
          if (state.status == AssociateStatus.bound && boundItem != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.success(name: boundItem.name))));
            context.pop(boundItem.id);
          }
        },
        builder: (BuildContext context, AssociateState state) {
          final Object? error = state.error;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppCard(
                  child: Text(t.identifier(type: identifierTypeLabel(identifier.type), value: identifier.rawValue)),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    children: <Widget>[
                      Text(errorMessage(error), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      if (error case IdentifierAlreadyBoundException(:final String boundItemId))
                        AppButton(
                          label: itemTrackerStrings.itemTracker.errors.openBoundItem,
                          variant: AppButtonVariant.text,
                          onPressed: () => context.pop(boundItemId),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppTextField(
                  label: t.search,
                  textInputAction: TextInputAction.search,
                  onChanged: cubit.search,
                ),
              ),
              if (state.status == AssociateStatus.searching || state.status == AssociateStatus.binding)
                const LinearProgressIndicator(),
              Expanded(
                child: state.status != AssociateStatus.searching && state.results.isEmpty
                    ? AppStatusView(icon: Icons.search_off, title: t.empty)
                    : ItemCardList(
                        items: state.results,
                        semanticLabelBuilder: (HouseholdItem item) => t.select(name: item.name),
                        onSelected: state.status == AssociateStatus.binding ? null : cubit.bind,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
