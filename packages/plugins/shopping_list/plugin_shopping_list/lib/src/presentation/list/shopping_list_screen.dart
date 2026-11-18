import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../domain/use_cases/list_queries.dart';
import '../../i18n/strings.g.dart';
import '../common/shopping_list_l10n.dart';
import '../export/shopping_export_sheet.dart';
import '../shopping_list_routes.dart';
import 'shopping_list_cubit.dart';
import 'shopping_list_feedback.dart';

/// Valor de las categorías que representa «Sin categoría».
const String _uncategorized = '';

/// Cuánto se resalta un item recién creado.
const Duration _highlightDuration = Duration(seconds: 2);

/// Cuántas categorías se ven en el panel antes de «N más».
const int _visibleCategories = 4;

/// Acciones del menú ⋮.
enum _ListMenuAction { categories, export }

/// Abre editar [item] y, si el formulario lo borró, ofrece deshacerlo.
Future<void> openShoppingItemEditor(BuildContext context, ShoppingItem item) async {
  final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
  final bool screenReader = MediaQuery.accessibleNavigationOf(context);
  final Object? result = await context.push<Object?>(ShoppingListRoutes.edit(item.id));
  if (result is ShoppingItem) {
    await cubit.deletedFromForm(result, offerSwipeTip: !screenReader);
  }
}

/// La lista de compras: lo que hay que comprar, con filtros fijos bajo la barra,
/// filas que se marcan, se editan con el lápiz y se borran deslizándolas, y un
/// campo para crear sin salir de la lista. Al final, los accesos a lo que
/// espera y a lo comprado.
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key, required this.exportSheet});

  /// Hoja de exportar; `null` si no hay forma de compartir.
  final ShoppingExportSheet Function(ShoppingListState state)? exportSheet;

  Future<void> _openMenu(BuildContext context, ShoppingListState state) async {
    final ShoppingListTranslations$shoppingList$list$es listStrings = shoppingListStrings.shoppingList.list;
    final ShoppingExportSheet Function(ShoppingListState state)? exportSheet = this.exportSheet;
    final _ListMenuAction? action = await showAppActionSheet<_ListMenuAction>(
      context,
      label: listStrings.moreActions,
      actions: <AppSheetAction<_ListMenuAction>>[
        AppSheetAction<_ListMenuAction>(value: _ListMenuAction.categories, label: listStrings.categories, icon: AppIcons.tag),
        if (exportSheet != null && state.snapshot.toBuy.isNotEmpty)
          AppSheetAction<_ListMenuAction>(value: _ListMenuAction.export, label: listStrings.export, icon: AppIcons.share),
      ],
    );
    if (!context.mounted) {
      return;
    }
    switch (action) {
      case _ListMenuAction.categories:
        await context.push<void>(ShoppingListRoutes.categories);
      case _ListMenuAction.export when exportSheet != null:
        await showAppBottomSheet<void>(context, builder: (BuildContext context) => exportSheet(state));
      case _ListMenuAction.export || null:
        break;
    }
  }

  void _onState(BuildContext context, ShoppingListState previous, ShoppingListState current) {
    final ShoppingListTranslations$shoppingList$es strings = shoppingListStrings.shoppingList;
    showShoppingFeedback(context, previous, current);
    if (current.status != ShoppingListStatus.ready) {
      return;
    }
    final ShoppingItem? added = current.lastAdded;
    final int toBuy = current.snapshot.toBuy.length;
    if (previous.status != ShoppingListStatus.ready) {
      announce(context, strings.dashboard.toBuyCount(n: toBuy));
    } else if (added != null && added != previous.lastAdded) {
      announce(context, strings.quickAdd.added(name: added.name));
    } else if (previous.filter != current.filter) {
      announce(context, strings.list.matchesAnnouncement(n: current.filtered.length));
    } else if (toBuy == 0 && previous.snapshot.toBuy.isNotEmpty && current.snapshot.entries.isNotEmpty) {
      announce(context, strings.list.allBoughtTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$es strings = shoppingListStrings.shoppingList;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    return BlocConsumer<ShoppingListCubit, ShoppingListState>(
      listenWhen: (ShoppingListState previous, ShoppingListState current) {
        _onState(context, previous, current);
        return false;
      },
      listener: (BuildContext context, ShoppingListState state) {},
      builder: (BuildContext context, ShoppingListState state) {
        final bool ready = state.status == ShoppingListStatus.ready;
        final bool hasItems = state.snapshot.entries.isNotEmpty;
        final bool showFilters = state.showFilters && hasItems;
        final QuickAddState? quickAdd = state.quickAdd;
        return Scaffold(
          appBar: AppTopBar(
            title: Semantics(header: true, child: Text(strings.title)),
            actions: <Widget>[
              if (hasItems)
                Semantics(
                  expanded: showFilters,
                  child: AppIconButton(
                    icon: AppIcons.slidersVertical,
                    tooltip: showFilters ? strings.list.closeFilters : strings.list.filters,
                    variant:
                        showFilters || state.isCustomized ? AppIconButtonVariant.tonal : AppIconButtonVariant.standard,
                    onPressed: cubit.toggleFilters,
                  ),
                ),
              if (ready)
                AppIconButton(
                  icon: AppIcons.ellipsisVertical,
                  tooltip: strings.list.moreActions,
                  onPressed: () => _openMenu(context, state),
                ),
            ],
          ),
          bottomNavigationBar: ready && quickAdd == null
              ? AppFooterActions(
                  children: <Widget>[
                    AppButton(label: strings.list.add, icon: AppIcons.plus, expand: true, onPressed: cubit.openQuickAdd),
                  ],
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showFilters) _FiltersPanel(state: state),
              Expanded(child: _Content(state: state)),
              if (quickAdd != null) _QuickAddBar(state: state, quickAdd: quickAdd),
            ],
          ),
        );
      },
    );
  }
}

/// Lo que va bajo los filtros: carga, lista vacía, todo comprado, nada
/// coincide o la lista.
class _Content extends StatelessWidget {
  const _Content({required this.state});

  final ShoppingListState state;

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$list$es listStrings = shoppingListStrings.shoppingList.list;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    final List<ShoppingGroup> groups = state.groups;
    return switch (state) {
      ShoppingListState(status: ShoppingListStatus.loading) => const AppLoadingView(),
      ShoppingListState(snapshot: ShoppingListSnapshot(entries: <ShoppingListEntry>[])) =>
        AppStatusView(icon: AppIcons.shoppingCart, title: listStrings.emptyTitle, message: listStrings.emptyMessage),
      _ when groups.isEmpty && state.filter.isDefault => _AllBought(state: state),
      _ when groups.isEmpty => AppStatusView(
          icon: AppIcons.slidersVertical,
          title: listStrings.noMatchesTitle,
          action: AppButton(
            label: listStrings.clearFilters,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            onPressed: cubit.resetFilters,
          ),
        ),
      _ => _ListBody(state: state, groups: groups),
    };
  }
}

/// No queda nada por comprar: distinto de la lista vacía, con acceso a lo
/// comprado y a lo que espera.
class _AllBought extends StatelessWidget {
  const _AllBought({required this.state});

  final ShoppingListState state;

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$list$es listStrings = shoppingListStrings.shoppingList.list;
    final int waitingCount = state.waiting.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: AppStatusView(
            icon: AppIcons.circleCheck,
            title: listStrings.allBoughtTitle,
            message: listStrings.allBoughtMessage,
            action: state.bought.isEmpty
                ? null
                : AppButton(
                    label: listStrings.showBought,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                    onPressed: () => context.push<void>(ShoppingListRoutes.bought),
                  ),
          ),
        ),
        if (waitingCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _SummaryRow(
              icon: AppIcons.hourglass,
              label: listStrings.summaryWaiting(n: waitingCount),
              semanticLabel: listStrings.summaryWaitingLabel(n: waitingCount),
              route: ShoppingListRoutes.waiting,
            ),
          ),
      ],
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.state, required this.groups});

  final ShoppingListState state;
  final List<ShoppingGroup> groups;

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$list$es listStrings = shoppingListStrings.shoppingList.list;
    final String? addedId = state.lastAdded?.id;
    final int waitingCount = state.waiting.length;
    final int boughtCount = state.bought.length;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: <Widget>[
        for (final ShoppingGroup group in groups) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Semantics(header: true, child: AppSectionHeader(_groupTitle(group), compact: true)),
          ),
          for (final ShoppingListEntry entry in group.entries)
            _EntryTile(
              key: ValueKey<String>(entry.item.id),
              entry: entry,
              grouping: state.grouping,
              highlighted: entry.item.id == addedId,
            ),
        ],
        if (waitingCount > 0)
          _SummaryRow(
            icon: AppIcons.hourglass,
            label: listStrings.summaryWaiting(n: waitingCount),
            semanticLabel: listStrings.summaryWaitingLabel(n: waitingCount),
            route: ShoppingListRoutes.waiting,
          ),
        if (boughtCount > 0)
          _SummaryRow(
            icon: AppIcons.circleCheck,
            label: listStrings.summaryBought(n: boughtCount),
            semanticLabel: listStrings.summaryBoughtLabel(n: boughtCount),
            route: ShoppingListRoutes.bought,
          ),
      ],
    );
  }

  String _groupTitle(ShoppingGroup group) => switch (group) {
        ShoppingGroup(urgency: final Urgency urgency) => urgencyLabel(urgency),
        ShoppingGroup(category: final ShoppingCategory category) => categoryName(category),
        _ => shoppingListStrings.shoppingList.list.uncategorized,
      };
}

/// «En espera · N» o «Comprados · N» al final de la lista: abre su pantalla.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.semanticLabel, required this.route});

  final IconData icon;
  final String label;
  final String semanticLabel;
  final String route;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: AppCard(
        semanticLabel: semanticLabel,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.s300, AppSpacing.s300, AppSpacing.s300),
        onTap: () => context.push<void>(route),
        child: Row(
          spacing: AppSpacing.s300,
          children: <Widget>[
            Icon(icon, color: colors.textSecondary),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            Icon(AppIcons.chevronRight, size: AppSizes.iconCompact, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// El panel de filtros fijo bajo la barra: categorías, urgencia, estado,
/// agrupación y, al pie, «Restablecer» y «Listo · N».
class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({required this.state});

  final ShoppingListState state;

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$list$es listStrings = shoppingListStrings.shoppingList.list;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    final ShoppingListFilter filter = state.filter;
    return AppPinnedPanel(
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          AppButton(
            label: listStrings.resetFilters,
            variant: AppButtonVariant.text,
            onPressed: state.isCustomized ? cubit.resetFilters : null,
          ),
          AppButton(
            label: listStrings.filtersDone(n: state.filtered.length),
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: cubit.toggleFilters,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: <Widget>[
          AppFilterChips<String>(
            label: listStrings.filterCategories,
            maxVisible: _visibleCategories,
            moreLabel: (int hidden) => listStrings.moreCategories(n: hidden),
            options: <AppChoice<String>>[
              for (final ShoppingCategory category in state.snapshot.categories)
                AppChoice<String>(value: category.id, label: categoryName(category)),
              AppChoice<String>(value: _uncategorized, label: listStrings.uncategorized),
            ],
            selected: <String>{...filter.categoryIds, if (filter.includeUncategorized) _uncategorized},
            onChanged: (Set<String> selected) => cubit.setFilter(filter.copyWith(
              categoryIds: <String>{for (final String id in selected) if (id != _uncategorized) id},
              includeUncategorized: selected.contains(_uncategorized),
            )),
          ),
          AppFilterChips<Urgency>(
            label: listStrings.filterUrgency,
            options: <AppChoice<Urgency>>[
              for (final Urgency urgency in Urgency.values)
                AppChoice<Urgency>(value: urgency, label: urgencyLabel(urgency)),
            ],
            selected: filter.urgencies,
            onChanged: (Set<Urgency> urgencies) => cubit.setFilter(filter.copyWith(urgencies: urgencies)),
          ),
          AppFilterChips<ShoppingItemState>(
            label: listStrings.filterState,
            options: <AppChoice<ShoppingItemState>>[
              for (final ShoppingItemState itemState in ShoppingItemState.values)
                AppChoice<ShoppingItemState>(value: itemState, label: stateLabel(itemState)),
            ],
            selected: filter.states,
            onChanged: (Set<ShoppingItemState> states) => cubit.setFilter(filter.copyWith(states: states)),
          ),
          AppChoiceSelector<ShoppingGrouping>(
            label: listStrings.groupBy,
            padding: EdgeInsets.zero,
            options: <AppChoice<ShoppingGrouping>>[
              AppChoice<ShoppingGrouping>(value: ShoppingGrouping.category, label: listStrings.groupByCategory),
              AppChoice<ShoppingGrouping>(value: ShoppingGrouping.urgency, label: listStrings.groupByUrgency),
            ],
            selected: state.grouping,
            onChanged: cubit.setGrouping,
          ),
        ],
      ),
    );
  }
}

/// Una fila de la lista: casilla, datos, lápiz y deslizar para borrar. Se lee
/// como un solo botón que abre editar, con la acción «Borrar» en el menú del
/// lector. Recién creada se resalta un momento y la lista baja hasta ella.
class _EntryTile extends StatefulWidget {
  const _EntryTile({super.key, required this.entry, required this.grouping, required this.highlighted});

  final ShoppingListEntry entry;
  final ShoppingGrouping grouping;
  final bool highlighted;

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _highlighted = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.highlighted) {
      _highlight();
    }
  }

  @override
  void didUpdateWidget(_EntryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlighted && !oldWidget.highlighted) {
      _highlight();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _highlight() {
    _highlighted = true;
    _timer?.cancel();
    _timer = Timer(_highlightDuration, () {
      if (mounted) {
        setState(() => _highlighted = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        unawaited(Scrollable.ensureVisible(context, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$list$es listStrings = shoppingListStrings.shoppingList.list;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    final ShoppingListEntry entry = widget.entry;
    final ShoppingItem item = entry.item;
    final String name = item.name;
    final Recurrence? recurrence = item.recurrence;
    final AppBadgeTone? urgency = urgencyTone(item.urgency);
    final ShoppingItemState itemState = entry.state;
    final bool purchased = itemState == ShoppingItemState.purchased;
    final String subtitle = <String>[
      if (item.quantity.isNotEmpty) item.quantity,
      if (recurrence != null) recurrenceLabel(recurrence),
    ].join(' · ');
    final List<ShoppingCategory> categories =
        widget.grouping == ShoppingGrouping.category ? entry.categories.skip(1).toList() : entry.categories;
    final bool showUrgency = urgency != null && !purchased;
    final bool showState = itemState != ShoppingItemState.pending;
    final String semanticLabel = '${<String>[
      name,
      if (subtitle.isNotEmpty) subtitle,
      if (showUrgency) urgencyLabel(item.urgency),
      if (showState) stateLabel(itemState),
      for (final ShoppingCategory category in categories) categoryName(category),
    ].join(', ')}. ${listStrings.editHint}';
    return AppSwipeToDelete(
      label: listStrings.swipeDelete,
      onDelete: () => cubit.delete(item),
      child: AppCheckTile(
        title: name,
        subtitle: subtitle.isEmpty ? null : subtitle,
        value: purchased,
        checkboxLabel: purchased ? listStrings.markPending(name: name) : listStrings.markPurchased(name: name),
        onChanged: (bool _) => cubit.toggle(entry),
        onTap: () => openShoppingItemEditor(context, item),
        action: AppTileAction(
          icon: AppIcons.pencil,
          tooltip: listStrings.edit(name: name),
          onPressed: () => openShoppingItemEditor(context, item),
        ),
        semanticLabel: semanticLabel,
        semanticActions: <CustomSemanticsAction, VoidCallback>{
          CustomSemanticsAction(label: listStrings.deleteAction(name: name)): () => cubit.delete(item),
        },
        highlighted: _highlighted,
        badges: <Widget>[
          if (showUrgency) AppBadge(label: urgencyLabel(item.urgency), tone: urgency, icon: AppIcons.exclamation),
          if (itemState == ShoppingItemState.overdue)
            AppBadge(label: stateLabel(itemState), tone: AppBadgeTone.warning, icon: AppIcons.clock)
          else if (itemState == ShoppingItemState.waiting)
            AppBadge(label: stateLabel(itemState), icon: AppIcons.hourglass),
          for (final ShoppingCategory category in categories) AppBadge(label: categoryName(category)),
        ],
      ),
    );
  }
}

/// El campo de crear sobre el teclado. Intro o Enviar crean el item y vacían
/// el campo; el chip dice en qué categoría irá y permite cambiarla.
class _QuickAddBar extends StatefulWidget {
  const _QuickAddBar({required this.state, required this.quickAdd});

  final ShoppingListState state;
  final QuickAddState quickAdd;

  @override
  State<_QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<_QuickAddBar> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit(String text) async {
    if (await context.read<ShoppingListCubit>().submitQuickAdd(text)) {
      _name.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$es strings = shoppingListStrings.shoppingList;
    final ShoppingListTranslations$shoppingList$quickAdd$es quickAddStrings = strings.quickAdd;
    final ShoppingListCubit cubit = context.read<ShoppingListCubit>();
    final QuickAddState quickAdd = widget.quickAdd;
    final List<AppChoice<String>> destinations = <AppChoice<String>>[
      for (final ShoppingCategory category in widget.state.snapshot.categories)
        AppChoice<String>(value: category.id, label: categoryName(category)),
      AppChoice<String>(value: _uncategorized, label: strings.list.uncategorized),
    ];
    final String selected = quickAdd.categoryId ?? _uncategorized;
    String labelOf(String value) =>
        destinations.firstWhere((AppChoice<String> option) => option.value == value, orElse: () => destinations.last).label;
    return AppComposeBar<String>(
      label: quickAddStrings.label,
      hint: quickAddStrings.hint,
      controller: _name,
      submitTooltip: quickAddStrings.submit,
      closeTooltip: quickAddStrings.close,
      onSubmitted: _submit,
      onClose: cubit.closeQuickAdd,
      errorText: switch (quickAdd.error) {
        QuickAddEmpty() => quickAddStrings.errorEmpty,
        QuickAddTooLong(:final int length) =>
          quickAddStrings.errorTooLong(max: ShoppingValidator.maxNameLength, n: length),
        null => null,
      },
      destinationLabel: quickAddStrings.destination,
      destinations: destinations,
      selectedDestination: selected,
      destinationSemanticLabel: quickAddStrings.destinationChip(category: labelOf(selected)),
      onDestinationChanged: (String value) {
        unawaited(cubit.chooseQuickAddCategory(value == _uncategorized ? null : value));
        announce(context, quickAddStrings.destinationChanged(category: labelOf(value)));
      },
    );
  }
}
