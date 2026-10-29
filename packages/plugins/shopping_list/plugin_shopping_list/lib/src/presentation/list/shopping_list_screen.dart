import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../domain/use_cases/list_queries.dart';
import '../../i18n/strings.g.dart';
import '../common/shopping_list_l10n.dart';
import '../export/shopping_export_sheet.dart';
import '../shopping_list_routes.dart';
import 'shopping_list_cubit.dart';

/// Valor del filtro de categorías que representa «Sin categoría».
const String _uncategorized = '';

/// La lista de compras: filtros, agrupación y marcar como comprado.
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key, required this.exportSheet});

  /// Hoja de exportar; `null` si no hay forma de compartir.
  final ShoppingExportSheet Function(ShoppingListState state)? exportSheet;

  Future<void> _confirmClearPurchased(BuildContext context) async {
    final ShoppingListTranslations$shoppingList$list$es t = shoppingListStrings.shoppingList.list;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    if (await showAppConfirmDialog(
      context,
      title: t.clearPurchasedTitle,
      message: t.clearPurchasedMessage,
      confirmLabel: t.clearPurchased,
      destructive: true,
    )) {
      await cubit.clearPurchased();
    }
  }

  void _showSnackBar(BuildContext context, SnackBar snackBar) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$es t = shoppingListStrings.shoppingList;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    final ShoppingExportSheet Function(ShoppingListState state)? exportSheet = this.exportSheet;
    return BlocConsumer<ShoppingListCubit, ShoppingListState>(
      listenWhen: (ShoppingListState previous, ShoppingListState current) =>
          (current.lastPurchase != null && current.lastPurchase != previous.lastPurchase) ||
          (current.error != null && current.error != previous.error),
      listener: (BuildContext context, ShoppingListState state) {
        final Object? error = state.error;
        if (error != null) {
          cubit.clearError();
          _showSnackBar(context, SnackBar(content: Text(errorMessage(error))));
          return;
        }
        _showSnackBar(
          context,
          SnackBar(
            content: Text(t.list.purchasedSnack(name: state.lastPurchase!.previous.name)),
            action: SnackBarAction(label: t.list.undo, onPressed: cubit.undoLastPurchase),
          ),
        );
      },
      builder: (BuildContext context, ShoppingListState state) => Scaffold(
        appBar: AppBar(
          title: Text(t.title),
          actions: <Widget>[
            if (state.hasPurchased)
              AppIconButton(
                icon: Icons.delete_sweep_outlined,
                tooltip: t.list.clearPurchased,
                onPressed: () => _confirmClearPurchased(context),
              ),
            if (exportSheet != null)
              AppIconButton(
                icon: Icons.ios_share,
                tooltip: t.list.export,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (BuildContext context) => exportSheet(state),
                ),
              ),
            AppIconButton(
              icon: Icons.tune,
              tooltip: t.list.filters,
              variant: state.filter.isEmpty && state.grouping == ShoppingGrouping.category
                  ? AppIconButtonVariant.standard
                  : AppIconButtonVariant.tonal,
              onPressed: cubit.toggleFilters,
            ),
            AppIconButton(
              icon: Icons.label_outline,
              tooltip: t.list.categories,
              onPressed: () => context.push(ShoppingListRoutes.categories),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              label: t.list.add,
              icon: Icons.add,
              expand: true,
              onPressed: () => context.push<String>(ShoppingListRoutes.create),
            ),
          ),
        ),
        body: switch (state) {
          ShoppingListState(status: ShoppingListStatus.loading) => const AppLoadingView(),
          ShoppingListState(snapshot: ShoppingListSnapshot(entries: <ShoppingListEntry>[])) =>
            AppStatusView(icon: Icons.shopping_cart_outlined, title: t.list.emptyTitle, message: t.list.emptyMessage),
          _ => _ListBody(state: state),
        },
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.state});

  final ShoppingListState state;

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$list$es t = shoppingListStrings.shoppingList.list;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    final List<ShoppingGroup> groups = state.groups;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: <Widget>[
        if (state.showFilters) _Filters(state: state),
        if (!state.showFilters && !state.filter.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(t.filtersActive)),
                AppButton(
                  label: t.clearFilters,
                  variant: AppButtonVariant.text,
                  onPressed: () => cubit.setFilter(const ShoppingListFilter()),
                ),
              ],
            ),
          ),
        if (groups.isEmpty)
          SizedBox(
            height: 320,
            child: AppStatusView(
              icon: Icons.filter_alt_off_outlined,
              title: t.noMatchesTitle,
              action: AppButton(
                label: t.clearFilters,
                variant: AppButtonVariant.secondary,
                onPressed: () => cubit.setFilter(const ShoppingListFilter()),
              ),
            ),
          ),
        for (final ShoppingGroup group in groups) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppSectionHeader(_groupTitle(group)),
          ),
          for (final ShoppingListEntry entry in group.entries)
            _EntryTile(key: ValueKey<String>(entry.item.id), entry: entry, grouping: state.grouping),
        ],
      ],
    );
  }

  String _groupTitle(ShoppingGroup group) => switch (group) {
        ShoppingGroup(urgency: final Urgency urgency) => urgencyLabel(urgency),
        ShoppingGroup(category: final ShoppingCategory category) => categoryName(category),
        _ => shoppingListStrings.shoppingList.list.uncategorized,
      };
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final ShoppingListState state;

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$list$es t = shoppingListStrings.shoppingList.list;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    final ShoppingListFilter filter = state.filter;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppFilterChips<String>(
            label: t.filterCategories,
            options: <AppChoice<String>>[
              for (final ShoppingCategory category in state.snapshot.categories)
                AppChoice<String>(value: category.id, label: categoryName(category)),
              AppChoice<String>(value: _uncategorized, label: t.uncategorized),
            ],
            selected: <String>{...filter.categoryIds, if (filter.includeUncategorized) _uncategorized},
            onChanged: (Set<String> selected) => cubit.setFilter(filter.copyWith(
              categoryIds: <String>{for (final String id in selected) if (id != _uncategorized) id},
              includeUncategorized: selected.contains(_uncategorized),
            )),
          ),
          const SizedBox(height: AppSpacing.md),
          AppFilterChips<Urgency>(
            label: t.filterUrgency,
            options: <AppChoice<Urgency>>[
              for (final Urgency urgency in Urgency.values)
                AppChoice<Urgency>(value: urgency, label: urgencyLabel(urgency)),
            ],
            selected: filter.urgencies,
            onChanged: (Set<Urgency> urgencies) => cubit.setFilter(filter.copyWith(urgencies: urgencies)),
          ),
          const SizedBox(height: AppSpacing.md),
          AppFilterChips<ShoppingItemState>(
            label: t.filterState,
            options: <AppChoice<ShoppingItemState>>[
              for (final ShoppingItemState itemState in ShoppingItemState.values)
                AppChoice<ShoppingItemState>(value: itemState, label: stateLabel(itemState)),
            ],
            selected: filter.states,
            onChanged: (Set<ShoppingItemState> states) => cubit.setFilter(filter.copyWith(states: states)),
          ),
          AppChoiceSelector<ShoppingGrouping>(
            label: t.groupBy,
            options: <AppChoice<ShoppingGrouping>>[
              AppChoice<ShoppingGrouping>(value: ShoppingGrouping.category, label: t.groupByCategory),
              AppChoice<ShoppingGrouping>(value: ShoppingGrouping.urgency, label: t.groupByUrgency),
            ],
            selected: state.grouping,
            onChanged: cubit.setGrouping,
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({super.key, required this.entry, required this.grouping});

  final ShoppingListEntry entry;
  final ShoppingGrouping grouping;

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$list$es t = shoppingListStrings.shoppingList.list;
    final ShoppingItem item = entry.item;
    final Recurrence? recurrence = item.recurrence;
    final AppBadgeTone? urgency = urgencyTone(item.urgency);
    final bool purchased = entry.state == ShoppingItemState.purchased;
    final String subtitle = <String>[
      if (item.quantity.isNotEmpty) item.quantity,
      if (recurrence != null) recurrenceLabel(recurrence),
    ].join(' · ');
    final List<ShoppingCategory> categories =
        grouping == ShoppingGrouping.category ? entry.categories.skip(1).toList() : entry.categories;
    return AppCheckTile(
      title: item.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      value: purchased,
      checkboxLabel: purchased ? t.markPending(name: item.name) : t.markPurchased(name: item.name),
      onChanged: (bool _) => context.read<ShoppingListCubit>().toggle(entry),
      onTap: () => context.push<String>(ShoppingListRoutes.edit(item.id)),
      badges: <Widget>[
        if (urgency != null && !purchased)
          AppBadge(label: urgencyLabel(item.urgency), tone: urgency, icon: Icons.priority_high),
        if (entry.state == ShoppingItemState.overdue)
          AppBadge(label: stateLabel(entry.state), tone: AppBadgeTone.warning, icon: Icons.schedule)
        else if (entry.state == ShoppingItemState.waiting)
          AppBadge(label: stateLabel(entry.state), icon: Icons.hourglass_empty),
        for (final ShoppingCategory category in categories) AppBadge(label: categoryName(category)),
      ],
    );
  }
}
