import 'package:core_sync/core_sync.dart';
import 'package:recurrence/recurrence.dart';
import 'package:urgency/urgency.dart';

import '../entities/household_task.dart';
import '../entities/task_category.dart';

/// Colecciones de la lista de tareas en la sincronización.
abstract final class TaskListCollections {
  static const String tasks = 'task_list.tasks';
  static const String categories = 'task_list.categories';

  static const Set<String> all = <String>{tasks, categories};
}

/// Conversión entre las entidades de la lista de tareas y sus campos
/// sincronizados.
///
/// Los instantes viajan en ISO 8601 (UTC), la fecha límite como día
/// (`2026-11-12`) y los enums por su nombre. `categoryIds` es un conjunto: se
/// fusiona elemento a elemento. Los campos de una escritura normal no llevan
/// `deletedAt`, así que nunca deshacen un borrado; el borrado se escribe con
/// [deletion].
abstract final class TaskListCodec {
  static const String deletedAt = 'deletedAt';
  static const String categoryIds = 'categoryIds';

  static Map<String, Object?> taskFields(HouseholdTask task) {
    final Recurrence? recurrence = task.recurrence;
    final DateTime? dueDate = task.dueDate;
    return <String, Object?>{
      'title': task.title,
      'urgency': task.urgency.name,
      'status': task.status.name,
      categoryIds: task.categoryIds.toSet(),
      'dueDate': dueDate == null ? null : _day(dueDate),
      'recurrence': recurrence == null
          ? null
          : <String, Object?>{'minDays': recurrence.minDays, 'maxDays': recurrence.maxDays},
      'lastDoneAt': _dateOrNull(task.lastDoneAt),
      'createdAt': _date(task.createdAt),
      'updatedAt': _date(task.updatedAt),
    };
  }

  /// La tarea, o `null` si a [entity] aún le falta algún campo obligatorio.
  /// Una recurrencia inválida se lee como ninguna y, si hay recurrencia, la
  /// fecha se ignora.
  static HouseholdTask? taskOf(SyncedEntity entity) {
    final Map<String, Object?> fields = entity.fields;
    final Object? title = fields['title'];
    final Urgency? urgency = _enumOf(Urgency.values, fields['urgency']);
    final TaskStatus? status = _enumOf(TaskStatus.values, fields['status']);
    final Object? createdAt = fields['createdAt'];
    if (title is! String || urgency == null || status == null || createdAt is! String) {
      return null;
    }
    final Object? updatedAt = fields['updatedAt'];
    final Object? lastDoneAt = fields['lastDoneAt'];
    final Object? dueDate = fields['dueDate'];
    final Object? categories = fields[categoryIds];
    final Recurrence? recurrence = _recurrenceOf(fields['recurrence']);
    return HouseholdTask(
      id: entity.id,
      title: title,
      urgency: urgency,
      status: status,
      categoryIds: categories is List ? List<String>.unmodifiable(categories.whereType<String>()) : const <String>[],
      dueDate: recurrence == null && dueDate is String ? _parseDay(dueDate) : null,
      recurrence: recurrence,
      lastDoneAt: lastDoneAt is String ? DateTime.parse(lastDoneAt) : null,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt is String ? DateTime.parse(updatedAt) : DateTime.parse(createdAt),
    );
  }

  static Map<String, Object?> categoryFields(TaskCategory category) => <String, Object?>{
        'name': category.name,
        'defaultKey': category.defaultKey,
        'sortOrder': category.sortOrder,
      };

  /// La categoría, o `null` si a [entity] le falta el orden o no tiene ni
  /// nombre ni clave por defecto.
  static TaskCategory? categoryOf(SyncedEntity entity) {
    final Map<String, Object?> fields = entity.fields;
    final Object? sortOrder = fields['sortOrder'];
    final Object? name = fields['name'];
    final Object? defaultKey = fields['defaultKey'];
    if (sortOrder is! int || (name is! String && defaultKey is! String)) {
      return null;
    }
    return TaskCategory(
      id: entity.id,
      sortOrder: sortOrder,
      name: name is String ? name : null,
      defaultKey: defaultKey is String ? defaultKey : null,
    );
  }

  /// Campos que borran una entidad en [at].
  static Map<String, Object?> deletion(DateTime at) => <String, Object?>{deletedAt: _date(at)};

  /// Momento del borrado guardado en [entity], o `null` si no está borrada.
  static DateTime? deletedAtOf(SyncedEntity entity) {
    final Object? value = entity.fields[deletedAt];
    return value is String ? DateTime.parse(value) : null;
  }

  static String _date(DateTime value) => value.toUtc().toIso8601String();

  static String? _dateOrNull(DateTime? value) => value == null ? null : _date(value);

  static String _day(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDay(String value) {
    final DateTime? parsed = DateTime.tryParse(value);
    return parsed == null ? null : DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  static T? _enumOf<T extends Enum>(List<T> values, Object? name) =>
      values.where((T value) => value.name == name).firstOrNull;

  static Recurrence? _recurrenceOf(Object? value) {
    if (value is! Map || value['minDays'] is! int || value['maxDays'] is! int) {
      return null;
    }
    try {
      return Recurrence.between(value['minDays'] as int, value['maxDays'] as int);
    } on ArgumentError {
      return null;
    }
  }
}
