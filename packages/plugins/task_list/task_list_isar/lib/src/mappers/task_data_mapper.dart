import 'package:task_list_domain/task_list_domain.dart';

import '../models/isar_task.dart';
import '../models/isar_task_category.dart';

/// Conversión bidireccional entre entidades de dominio y colecciones Isar.
///
/// Isar devuelve las fechas en hora local: al leer se convierten siempre a
/// UTC. La fecha límite se vuelve a llevar a la medianoche UTC de su día.
abstract final class TaskDataMapper {
  static IsarTask toIsarTask(HouseholdTask task) => IsarTask()
    ..id = task.id
    ..title = task.title
    ..urgency = task.urgency
    ..status = task.status
    ..categoryIds = task.categoryIds.toList()
    ..dueDate = task.dueDate?.toUtc()
    ..recurrenceMinDays = task.recurrence?.minDays
    ..recurrenceMaxDays = task.recurrence?.maxDays
    ..lastDoneAt = task.lastDoneAt?.toUtc()
    ..createdAt = task.createdAt.toUtc()
    ..updatedAt = task.updatedAt.toUtc();

  static HouseholdTask fromIsarTask(IsarTask model) {
    final int? minDays = model.recurrenceMinDays;
    final int? maxDays = model.recurrenceMaxDays;
    final DateTime? dueDate = model.dueDate?.toUtc();
    return HouseholdTask(
      id: model.id,
      title: model.title,
      urgency: model.urgency,
      status: model.status,
      categoryIds: List<String>.unmodifiable(model.categoryIds),
      dueDate: dueDate == null ? null : CalendarDay.of(dueDate),
      recurrence: minDays == null || maxDays == null ? null : Recurrence.between(minDays, maxDays),
      lastDoneAt: model.lastDoneAt?.toUtc(),
      createdAt: model.createdAt.toUtc(),
      updatedAt: model.updatedAt.toUtc(),
    );
  }

  static IsarTaskCategory toIsarCategory(TaskCategory category) => IsarTaskCategory()
    ..id = category.id
    ..name = category.name
    ..defaultKey = category.defaultKey
    ..sortOrder = category.sortOrder;

  static TaskCategory fromIsarCategory(IsarTaskCategory model) => TaskCategory(
        id: model.id,
        name: model.name,
        defaultKey: model.defaultKey,
        sortOrder: model.sortOrder,
      );
}
