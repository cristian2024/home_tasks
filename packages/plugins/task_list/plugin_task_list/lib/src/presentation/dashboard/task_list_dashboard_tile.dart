import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../../domain/use_cases/list_queries.dart';
import '../../i18n/strings.g.dart';
import '../task_list_routes.dart';

/// Tarjeta del plugin en el inicio: cuánto hay por hacer y, para que quepa,
/// una sola etiqueta: lo atrasado si lo hay y, si no, lo urgente. Abre la
/// lista.
class TaskListDashboardTile extends StatelessWidget {
  const TaskListDashboardTile({super.key, required this.watchList});

  final WatchTaskList watchList;

  @override
  Widget build(BuildContext context) {
    final TaskListTranslations$taskList$es strings = taskListStrings.taskList;
    final TaskListTranslations$taskList$dashboard$es dashboardStrings = strings.dashboard;
    return StreamBuilder<TaskListSnapshot>(
      stream: watchList(),
      builder: (BuildContext context, AsyncSnapshot<TaskListSnapshot> snapshot) {
        final TaskListSummary? summary = snapshot.data?.summary;
        return AppModuleCard(
          icon: AppIcons.listChecks,
          title: strings.title,
          summary: summary == null ? strings.description : dashboardStrings.toDoCount(n: summary.toDo),
          badges: <Widget>[
            if (summary != null && summary.overdue > 0)
              AppBadge(label: dashboardStrings.overdueCount(n: summary.overdue), tone: AppBadgeTone.warning, icon: AppIcons.clock)
            else if (summary != null && summary.urgent > 0)
              AppBadge(label: dashboardStrings.urgentCount(n: summary.urgent), tone: AppBadgeTone.critical, icon: AppIcons.exclamation),
          ],
          onTap: () => context.push<void>(TaskListRoutes.base),
        );
      },
    );
  }
}
