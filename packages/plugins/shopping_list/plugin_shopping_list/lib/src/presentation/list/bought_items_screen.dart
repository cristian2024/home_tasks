import 'package:core_utils/core_utils.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/shopping_list_l10n.dart';
import 'shopping_list_cubit.dart';
import 'shopping_list_feedback.dart';

/// Lo comprado, de lo más reciente a lo más antiguo, con la fecha de compra.
/// Al desmarcar, el item vuelve a pendiente (con «Deshacer»). Al pie, «Borrar
/// comprados», que pide confirmación.
class BoughtItemsScreen extends StatelessWidget {
  const BoughtItemsScreen({super.key, required this.today});

  /// El día de hoy (`Clock.today`), para las fechas relativas.
  final DateTime Function() today;

  Future<void> _confirmClear(BuildContext context) async {
    final ShoppingListTranslations$shoppingList$list$es listStrings = shoppingListStrings.shoppingList.list;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    if (await showAppConfirmDialog(
      context,
      title: listStrings.clearPurchasedTitle,
      message: listStrings.clearPurchasedMessage,
      confirmLabel: listStrings.clearPurchased,
      destructive: true,
    )) {
      await cubit.clearPurchased();
    }
  }

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
        final List<ShoppingListEntry> bought = state.bought;
        final DateTime day = today();
        return Scaffold(
          appBar: AppTopBar(title: Semantics(header: true, child: Text(strings.bought.title))),
          bottomNavigationBar: bought.isEmpty
              ? null
              : AppFooterActions(
                  children: <Widget>[
                    AppButton(
                      label: strings.list.clearPurchased,
                      icon: AppIcons.trash,
                      variant: AppButtonVariant.secondary,
                      expand: true,
                      onPressed: () => _confirmClear(context),
                    ),
                  ],
                ),
          body: switch (state.status) {
            ShoppingListStatus.loading => const AppLoadingView(),
            _ when bought.isEmpty => AppStatusView(icon: AppIcons.circleCheck, title: strings.bought.empty),
            _ => ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                children: <Widget>[
                  for (final ShoppingListEntry entry in bought)
                    _BoughtTile(key: ValueKey<String>(entry.item.id), entry: entry, today: day),
                ],
              ),
          },
        );
      },
    );
  }
}

class _BoughtTile extends StatelessWidget {
  const _BoughtTile({super.key, required this.entry, required this.today});

  final ShoppingListEntry entry;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ShoppingItem item = entry.item;
    final DateTime? lastPurchasedAt = item.lastPurchasedAt;
    final DateTime? day = lastPurchasedAt == null ? null : CalendarDay.localDayOf(lastPurchasedAt);
    return AppCheckTile(
      title: item.name,
      subtitle: day == null ? null : relativeDate(day, today: today),
      value: true,
      checkboxLabel: shoppingListStrings.shoppingList.list.markPending(name: item.name),
      semanticLabel: day == null ? item.name : '${item.name}, ${boughtOn(day, today: today)}',
      onChanged: (bool _) => context.read<ShoppingListCubit>().toggle(entry),
    );
  }
}
