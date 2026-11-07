import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../../i18n/strings.g.dart';

TaskListTranslations$taskList$es get _strings => taskListStrings.taskList;

String urgencyLabel(Urgency urgency) => switch (urgency) {
      Urgency.immediate => _strings.urgency.immediate,
      Urgency.high => _strings.urgency.high,
      Urgency.normal => _strings.urgency.normal,
      Urgency.low => _strings.urgency.low,
    };

/// Solo las urgencias altas llevan etiqueta.
bool hasUrgencyBadge(Urgency urgency) => urgency.isUrgent;

/// Nombre de los estados por los que se puede filtrar.
String stateLabel(TaskState state) => switch (state) {
      TaskState.overdue => _strings.states.overdue,
      TaskState.waiting => _strings.states.waiting,
      _ => _strings.states.noDate,
    };

String groupTitle(TaskGroup group) {
  final TaskCategory? category = group.category;
  return switch (group.dateGroup) {
    TaskDateGroup.overdue => _strings.groups.overdue,
    TaskDateGroup.today => _strings.groups.today,
    TaskDateGroup.upcoming => _strings.groups.upcoming,
    TaskDateGroup.noDate => _strings.groups.noDate,
    null => category == null ? _strings.list.uncategorized : categoryName(category),
  };
}

/// Nombre visible: el que puso el usuario o, en una por defecto, su
/// traducción.
String categoryName(TaskCategory category) {
  final String? name = category.name;
  if (name != null) {
    return name;
  }
  return switch (DefaultTaskCategory.values.asNameMap()[category.defaultKey]) {
    DefaultTaskCategory.cleaning => _strings.defaultCategories.cleaning,
    DefaultTaskCategory.kitchen => _strings.defaultCategories.kitchen,
    DefaultTaskCategory.garden => _strings.defaultCategories.garden,
    DefaultTaskCategory.bills => _strings.defaultCategories.bills,
    DefaultTaskCategory.repairs => _strings.defaultCategories.repairs,
    null => category.defaultKey ?? category.id,
  };
}

String recurrenceLabel(Recurrence recurrence) => recurrence.isFixed
    ? _strings.recurrence.every(n: recurrence.minDays)
    : _strings.recurrence.between(min: recurrence.minDays, max: recurrence.maxDays);

/// Fecha corta: «12 nov» (en inglés, «Nov 12»).
String shortDate(DateTime day) {
  final TaskListTranslations$taskList$dates$months$es months = _strings.dates.months;
  final String month = <String>[
    months.m1,
    months.m2,
    months.m3,
    months.m4,
    months.m5,
    months.m6,
    months.m7,
    months.m8,
    months.m9,
    months.m10,
    months.m11,
    months.m12,
  ][day.month - 1];
  return _strings.dates.short(day: day.day, month: month);
}

/// «Ayer», «Hoy», «Mañana» o la fecha corta.
String relativeDate(DateTime day, {required DateTime today}) => switch (CalendarDay.relativeTo(day, today: today)) {
      RelativeDay.yesterday => _strings.dates.yesterday,
      RelativeDay.today => _strings.dates.today,
      RelativeDay.tomorrow => _strings.dates.tomorrow,
      RelativeDay.other => shortDate(day),
    };

/// La fecha completa, para los lectores de pantalla («viernes, 6 de
/// noviembre de 2026»).
String fullDate(BuildContext context, DateTime day) =>
    MaterialLocalizations.of(context).formatFullDate(DateTime(day.year, day.month, day.day));

/// La línea de datos de una fila y su versión para los lectores de pantalla,
/// con las fechas completas. Agrupada por categoría, la primera categoría ya
/// es el grupo y no se repite.
({String? text, String? semantics}) entryMeta(
  BuildContext context,
  TaskListEntry entry, {
  required DateTime today,
  required TaskGrouping grouping,
}) {
  final HouseholdTask task = entry.task;
  final Recurrence? recurrence = task.recurrence;
  final DateTime? dueDate = task.dueDate;
  final DateTime? returnsOn = entry.state == TaskState.waiting ? task.returnsOn : null;
  final TaskCategory? category = grouping == TaskGrouping.category ? null : entry.primaryCategory;
  final List<(String, String)> parts = <(String, String)>[
    if (recurrence != null) (recurrenceLabel(recurrence), recurrenceLabel(recurrence)),
    if (returnsOn != null)
      (
        _strings.recurrence.returnsOn(date: shortDate(returnsOn)),
        _strings.recurrence.returnsOn(date: fullDate(context, returnsOn)),
      ),
    if (dueDate != null && entry.state != TaskState.today)
      (relativeDate(dueDate, today: today), fullDate(context, dueDate)),
    if (category != null) (categoryName(category), categoryName(category)),
  ];
  if (parts.isEmpty) {
    return (text: null, semantics: null);
  }
  return (
    text: parts.map(((String, String) part) => part.$1).join(' · '),
    semantics: parts.map(((String, String) part) => part.$2).join(', '),
  );
}

/// Las etiquetas de una fila: la urgencia alta, el atraso si el grupo no lo
/// dice ya y la espera.
List<Widget> entryBadges(TaskListEntry entry, {required bool showOverdue}) => <Widget>[
      if (hasUrgencyBadge(entry.task.urgency) && entry.state != TaskState.done)
        AppBadge(label: urgencyLabel(entry.task.urgency), tone: AppBadgeTone.critical, icon: AppIcons.exclamation),
      if (entry.state == TaskState.overdue && showOverdue)
        AppBadge(label: _strings.states.overdue, tone: AppBadgeTone.warning, icon: AppIcons.clock),
      if (entry.state == TaskState.waiting) AppBadge(label: _strings.states.waiting, icon: AppIcons.hourglass),
    ];

String validationMessage(TaskValidationException error) => switch ((error.field, error.reason)) {
      (TaskValidationField.title, TaskValidationReason.empty) => _strings.errors.titleRequired,
      (_, TaskValidationReason.empty) => _strings.errors.titleRequired,
      (TaskValidationField.title, TaskValidationReason.tooLong) =>
        _strings.errors.tooLong(max: TaskValidator.maxTitleLength),
      (TaskValidationField.categoryName, TaskValidationReason.tooLong) =>
        _strings.errors.tooLong(max: TaskValidator.maxCategoryNameLength),
    };

/// Mensaje de un error de la lista; otro error usa el texto genérico.
String errorMessage(Object error, {required String unexpected}) => switch (error) {
      TaskNotFoundException() => _strings.errors.taskNotFound,
      TaskCategoryNotFoundException() => _strings.errors.categoryNotFound,
      TaskCategoryNameTakenException(:final String name) => _strings.errors.categoryNameTaken(name: name),
      TaskValidationException() => validationMessage(error),
      _ => unexpected,
    };
