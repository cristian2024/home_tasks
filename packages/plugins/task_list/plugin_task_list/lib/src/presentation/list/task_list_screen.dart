import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../../domain/use_cases/completion_use_cases.dart';
import '../../i18n/strings.g.dart';
import '../common/task_list_l10n.dart';
import '../task_list_routes.dart';
import 'task_list_cubit.dart';

/// Valor del filtro de categorías que representa «Sin categoría».
const String _uncategorized = '';

/// Acciones del menú ⋮.
enum _ListMenuAction { categories, clearDone }

void _announce(BuildContext context, String message) =>
    SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context));

/// La lista de tareas: grupos por fecha o categoría, filtros y completar.
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  Future<void> _openMenu(BuildContext context, TaskListState state) async {
    final TaskListTranslations$taskList$list$es listStrings = taskListStrings.taskList.list;
    final _ListMenuAction? action = await showAppActionSheet<_ListMenuAction>(
      context,
      label: listStrings.moreActions,
      actions: <AppSheetAction<_ListMenuAction>>[
        AppSheetAction<_ListMenuAction>(value: _ListMenuAction.categories, label: listStrings.categories, icon: AppIcons.tag),
        if (state.done.isNotEmpty)
          AppSheetAction<_ListMenuAction>(
            value: _ListMenuAction.clearDone,
            label: listStrings.clearDone,
            icon: AppIcons.trash2,
            destructive: true,
          ),
      ],
    );
    if (!context.mounted) {
      return;
    }
    switch (action) {
      case _ListMenuAction.categories:
        await context.push<void>(TaskListRoutes.categories);
      case _ListMenuAction.clearDone:
        await confirmClearDone(context, count: state.done.length);
      case null:
        break;
    }
  }

  void _onState(BuildContext context, TaskListState previous, TaskListState current) {
    final TaskListTranslations$taskList$list$es listStrings = taskListStrings.taskList.list;
    final TaskListCubit cubit = context.read<TaskListCubit>();
    final Object? error = current.error;
    if (error != null && error != previous.error) {
      cubit.clearError();
      showTaskSnackBar(context, SnackBar(content: Text(errorMessage(error, unexpected: commonStrings.common.unexpectedError))));
      return;
    }
    final TaskCompletion? completion = current.lastCompletion;
    if (completion != null && completion != previous.lastCompletion) {
      final HouseholdTask task = completion.completed;
      final DateTime? returnsOn = task.returnsOn;
      showTaskSnackBar(
        context,
        SnackBar(
          content: Text(
            returnsOn == null
                ? listStrings.doneSnack(name: task.title)
                : listStrings.returnsSnack(name: task.title, date: shortDate(returnsOn)),
          ),
          action: SnackBarAction(label: listStrings.undo, onPressed: cubit.undoLastCompletion),
          duration: TaskListCubit.undoDuration,
          persist: false,
        ),
      );
      return;
    }
    if (previous.status != TaskListStatus.ready && current.status == TaskListStatus.ready) {
      _announce(context, listStrings.toDoAnnouncement(n: current.snapshot.summary.toDo));
    } else if (current.status == TaskListStatus.ready && previous.filter != current.filter) {
      final int matches = current.filtered.where((TaskListEntry entry) => entry.state != TaskState.done).length;
      _announce(context, listStrings.matchesAnnouncement(n: matches));
    }
  }

  @override
  Widget build(BuildContext context) {
    final TaskListTranslations$taskList$es strings = taskListStrings.taskList;
    final TaskListCubit cubit = context.read<TaskListCubit>();
    return BlocConsumer<TaskListCubit, TaskListState>(
      listenWhen: (TaskListState previous, TaskListState current) {
        _onState(context, previous, current);
        return false;
      },
      listener: (BuildContext context, TaskListState state) {},
      builder: (BuildContext context, TaskListState state) {
        final bool showFilters = state.showFilters;
        // Mientras carga o si falló, ni menú ni añadir: no hay lista sobre la que actuar.
        final bool ready = state.status == TaskListStatus.ready;
        return Scaffold(
          appBar: AppTopBar(
            title: Text(strings.title),
            actions: <Widget>[
              if (state.hasPending)
                AppIconButton(
                  icon: AppIcons.slidersVertical,
                  tooltip: showFilters ? strings.list.closeFilters : strings.list.filters,
                  variant: showFilters || state.isCustomized ? AppIconButtonVariant.tonal : AppIconButtonVariant.standard,
                  onPressed: cubit.toggleFilters,
                ),
              if (ready)
                AppIconButton(
                  icon: AppIcons.ellipsisVertical,
                  tooltip: strings.list.moreActions,
                  onPressed: () => _openMenu(context, state),
                ),
            ],
          ),
          bottomNavigationBar: ready
              ? AppFooterActions(
                  children: <Widget>[
                    AppButton(
                      label: strings.list.add,
                      icon: AppIcons.plus,
                      expand: true,
                      onPressed: () => context.push<String>(TaskListRoutes.create),
                    ),
                  ],
                )
              : null,
          body: switch (state) {
            TaskListState(status: TaskListStatus.loading) => const _Loading(),
            TaskListState(status: TaskListStatus.failed) => AppStatusView(
                icon: AppIcons.circleAlert,
                title: strings.list.loadError,
                action: AppButton(
                  label: strings.list.retry,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  onPressed: cubit.retry,
                ),
              ),
            _ when state.snapshot.entries.isEmpty =>
              AppStatusView(icon: AppIcons.listChecks, title: strings.list.emptyTitle, message: strings.list.emptyMessage),
            TaskListState(hasPending: false) => _AllDone(doneCount: state.done.length),
            TaskListState(showFilters: false, groups: <TaskGroup>[]) => _NoMatches(onClear: _clearFilters(cubit)),
            _ => _ListBody(state: state),
          },
        );
      },
    );
  }
}

VoidCallback _clearFilters(TaskListCubit cubit) => () => cubit.setFilter(const TaskListFilter());

/// Muestra [snackBar] sin dejar otros en cola.
void showTaskSnackBar(BuildContext context, SnackBar snackBar) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(snackBar);

/// Pide confirmación y borra las tareas hechas.
Future<void> confirmClearDone(BuildContext context, {required int count}) async {
  final TaskListTranslations$taskList$done$es doneStrings = taskListStrings.taskList.done;
  final TaskListCubit cubit = context.read<TaskListCubit>();
  if (!await showAppConfirmDialog(
    context,
    title: doneStrings.clearTitle(n: count),
    message: doneStrings.clearMessage,
    confirmLabel: taskListStrings.taskList.delete,
    destructive: true,
  )) {
    return;
  }
  if (await cubit.clearDone() > 0 && context.mounted) {
    showTaskSnackBar(context, SnackBar(content: Text(doneStrings.cleared)));
  }
}

/// Cargando. Si tarda más de dos segundos, lo dice en pantalla y lo anuncia.
class _Loading extends StatefulWidget {
  const _Loading();

  @override
  State<_Loading> createState() => _LoadingState();
}

class _LoadingState extends State<_Loading> {
  static const Duration _announceAfter = Duration(seconds: 2);
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_announceAfter, () {
      if (mounted) {
        setState(() => _slow = true);
        _announce(context, taskListStrings.taskList.list.loading);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _slow
      ? AppStatusView(icon: AppIcons.listChecks, title: taskListStrings.taskList.list.loading)
      : const AppLoadingView();
}

/// No queda nada por hacer: hay tareas, pero todas hechas.
class _AllDone extends StatelessWidget {
  const _AllDone({required this.doneCount});

  final int doneCount;

  @override
  Widget build(BuildContext context) {
    final TaskListTranslations$taskList$list$es listStrings = taskListStrings.taskList.list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: AppStatusView(
            icon: AppIcons.circleCheck,
            title: listStrings.allDoneTitle,
            message: listStrings.allDoneMessage,
          ),
        ),
        if (doneCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _DoneRow(count: doneCount),
          ),
      ],
    );
  }
}

/// Nada coincide con los filtros.
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final TaskListTranslations$taskList$list$es listStrings = taskListStrings.taskList.list;
    return AppStatusView(
      icon: AppIcons.slidersVertical,
      title: listStrings.noMatchesTitle,
      action: AppButton(
        label: listStrings.clearFilters,
        variant: AppButtonVariant.secondary,
        size: AppButtonSize.medium,
        onPressed: onClear,
      ),
    );
  }
}

/// La fila «Hechas · N», que abre las hechas.
class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final TaskListTranslations$taskList$list$es listStrings = taskListStrings.taskList.list;
    final AppThemeColors colors = AppThemeColors.of(context);
    return AppCard(
      semanticLabel: listStrings.doneRowLabel(n: count),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.s300, AppSpacing.s300, AppSpacing.s300),
      onTap: () => context.push<void>(TaskListRoutes.done),
      child: Row(
        spacing: AppSpacing.s300,
        children: <Widget>[
          Icon(AppIcons.circleCheck, color: colors.textSecondary),
          Expanded(child: Text(listStrings.doneRow(n: count), style: Theme.of(context).textTheme.bodyLarge)),
          Icon(AppIcons.chevronRight, size: AppSizes.iconCompact, color: colors.textTertiary),
        ],
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.state});

  final TaskListState state;

  @override
  Widget build(BuildContext context) {
    final List<TaskGroup> groups = state.groups;
    final bool showFilters = state.showFilters;
    final int doneCount = state.done.length;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: <Widget>[
        if (showFilters) _Filters(state: state),
        if (groups.isEmpty) SizedBox(height: 320, child: _NoMatches(onClear: _clearFilters(context.read<TaskListCubit>()))),
        for (final TaskGroup group in groups) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppSectionHeader(groupTitle(group), compact: true),
          ),
          for (final TaskListEntry entry in group.entries) _TaskTile(key: ValueKey<String>(entry.task.id), entry: entry, state: state),
        ],
        if (doneCount > 0 && !showFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.s0),
            child: _DoneRow(count: doneCount),
          ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final TaskListState state;

  @override
  Widget build(BuildContext context) {
    final TaskListTranslations$taskList$list$es listStrings = taskListStrings.taskList.list;
    final TaskListCubit cubit = context.read<TaskListCubit>();
    final TaskListFilter filter = state.filter;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: <Widget>[
          AppFilterChips<String>(
            label: listStrings.filterCategories,
            options: <AppChoice<String>>[
              for (final TaskCategory category in state.snapshot.categories)
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
              for (final Urgency urgency in Urgency.values) AppChoice<Urgency>(value: urgency, label: urgencyLabel(urgency)),
            ],
            selected: filter.urgencies,
            onChanged: (Set<Urgency> urgencies) => cubit.setFilter(filter.copyWith(urgencies: urgencies)),
          ),
          AppFilterChips<TaskState>(
            label: listStrings.filterState,
            options: <AppChoice<TaskState>>[
              for (final TaskState taskState in TaskListFilter.filterableStates)
                AppChoice<TaskState>(value: taskState, label: stateLabel(taskState)),
            ],
            selected: filter.states,
            onChanged: (Set<TaskState> states) => cubit.setFilter(filter.copyWith(states: states)),
          ),
          AppChoiceSelector<TaskGrouping>(
            label: listStrings.groupBy,
            padding: EdgeInsets.zero,
            options: <AppChoice<TaskGrouping>>[
              AppChoice<TaskGrouping>(value: TaskGrouping.date, label: listStrings.groupByDate),
              AppChoice<TaskGrouping>(value: TaskGrouping.category, label: listStrings.groupByCategory),
            ],
            selected: state.grouping,
            onChanged: cubit.setGrouping,
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({super.key, required this.entry, required this.state});

  final TaskListEntry entry;
  final TaskListState state;

  @override
  Widget build(BuildContext context) {
    final TaskListTranslations$taskList$list$es listStrings = taskListStrings.taskList.list;
    final HouseholdTask task = entry.task;
    final bool checked = state.isPinned(entry);
    final ({String? text, String? semantics}) meta =
        entryMeta(context, entry, today: state.snapshot.today, grouping: state.grouping);
    return AppCheckTile(
      title: task.title,
      subtitle: meta.text,
      subtitleSemantics: meta.semantics,
      value: checked,
      checkboxLabel: checked ? listStrings.markPending(name: task.title) : listStrings.markDone(name: task.title),
      onChanged: (bool _) => context.read<TaskListCubit>().toggle(entry),
      onTap: () => context.push<String>(TaskListRoutes.edit(task.id)),
      badges: entryBadges(
        entry,
        showOverdue: state.grouping == TaskGrouping.category || !state.filter.isEmpty,
      ),
    );
  }
}
