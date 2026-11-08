import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/task_list_l10n.dart';
import '../list/task_list_cubit.dart';
import '../list/task_list_screen.dart';

/// Las tareas hechas, de la más reciente a la más antigua. Se pueden volver a
/// pendiente o borrar todas.
class DoneTasksScreen extends StatelessWidget {
  const DoneTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TaskListTranslations$taskList$done$es doneStrings = taskListStrings.taskList.done;
    return BlocBuilder<TaskListCubit, TaskListState>(
      builder: (BuildContext context, TaskListState state) {
        final List<TaskListEntry> done = state.done;
        return Scaffold(
          appBar: AppTopBar(title: Text(doneStrings.title)),
          bottomNavigationBar: done.isEmpty
              ? null
              : AppFooterActions(
                  children: <Widget>[
                    AppButton(
                      label: doneStrings.clear,
                      icon: AppIcons.trash2,
                      variant: AppButtonVariant.secondary,
                      expand: true,
                      onPressed: () => confirmClearDone(context, count: done.length),
                    ),
                  ],
                ),
          body: switch (state.status) {
            TaskListStatus.loading => const AppLoadingView(),
            _ when done.isEmpty => AppStatusView(icon: AppIcons.circleCheck, title: doneStrings.empty),
            _ => ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                children: <Widget>[
                  for (final TaskListEntry entry in done)
                    _DoneTile(key: ValueKey<String>(entry.task.id), entry: entry, today: state.snapshot.today),
                ],
              ),
          },
        );
      },
    );
  }
}

class _DoneTile extends StatelessWidget {
  const _DoneTile({super.key, required this.entry, required this.today});

  final TaskListEntry entry;
  final DateTime today;

  Future<void> _reopen(BuildContext context) async {
    final TextDirection direction = Directionality.of(context);
    final FlutterView view = View.of(context);
    await context.read<TaskListCubit>().toggle(entry);
    unawaited(
      SemanticsService.sendAnnouncement(view, taskListStrings.taskList.list.pendingAgain(name: entry.task.title), direction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HouseholdTask task = entry.task;
    final DateTime? lastDoneAt = task.lastDoneAt;
    final DateTime? doneOn = lastDoneAt == null ? null : CalendarDay.localDayOf(lastDoneAt);
    return AppCheckTile(
      title: task.title,
      subtitle: doneOn == null ? null : relativeDate(doneOn, today: today),
      subtitleSemantics: doneOn == null ? null : fullDate(context, doneOn),
      value: true,
      checkboxLabel: taskListStrings.taskList.list.markPending(name: task.title),
      onChanged: (bool _) => _reopen(context),
    );
  }
}
