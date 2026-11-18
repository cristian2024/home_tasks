import 'package:core_utils/core_utils.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/shopping_list_l10n.dart';
import 'shopping_list_cubit.dart';
import 'shopping_list_feedback.dart';
import 'shopping_list_screen.dart';

/// Lo que se repite y espera a su siguiente ventana, por la fecha en que
/// vuelve. Marcarlo lo compra antes de tiempo (con «Deshacer»); tocar la fila
/// abre editar.
class WaitingItemsScreen extends StatelessWidget {
  const WaitingItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$es strings = shoppingListStrings.shoppingList;
    return BlocConsumer<ShoppingListCubit, ShoppingListState>(
      listenWhen: (ShoppingListState previous, ShoppingListState current) {
        showShoppingFeedback(context, previous, current);
        return false;
      },
      listener: (BuildContext context, ShoppingListState state) {},
      builder: (BuildContext context, ShoppingListState state) {
        final List<ShoppingListEntry> waiting = state.waiting;
        return Scaffold(
          appBar: AppTopBar(title: Semantics(header: true, child: Text(strings.waiting.title))),
          body: switch (state.status) {
            ShoppingListStatus.loading => const AppLoadingView(),
            _ when waiting.isEmpty => AppStatusView(icon: AppIcons.hourglass, title: strings.waiting.empty),
            _ => ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                children: <Widget>[
                  for (final ShoppingListEntry entry in waiting)
                    _WaitingTile(key: ValueKey<String>(entry.item.id), entry: entry),
                ],
              ),
          },
        );
      },
    );
  }
}

class _WaitingTile extends StatelessWidget {
  const _WaitingTile({super.key, required this.entry});

  final ShoppingListEntry entry;

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$es strings = shoppingListStrings.shoppingList;
    final ShoppingItem item = entry.item;
    final Recurrence? recurrence = item.recurrence;
    final DateTime? returnsAt = item.returnsAt;
    final String? backOn =
        returnsAt == null ? null : strings.waiting.backOn(date: shortDate(CalendarDay.localDayOf(returnsAt)));
    final String subtitle = <String>[
      if (recurrence != null) recurrenceLabel(recurrence),
      ?backOn,
    ].join(' · ');
    return AppCheckTile(
      title: item.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      value: false,
      checkboxLabel: strings.list.markPurchased(name: item.name),
      semanticLabel: <String>[item.name, if (recurrence != null) recurrenceLabel(recurrence), ?backOn].join(', '),
      onChanged: (bool _) => context.read<ShoppingListCubit>().toggle(entry),
      onTap: () => openShoppingItemEditor(context, item),
    );
  }
}
