/// Dominio de la lista de tareas en Dart puro: tareas y categorías, reglas de
/// validación, estado, filtro y agrupación, errores, el contrato del
/// repositorio y su sincronización. No depende de Flutter ni de ningún motor
/// de base de datos.
library;

export 'package:categories/categories.dart';
export 'package:core_utils/core_utils.dart' show CalendarDay, RelativeDay;
export 'package:recurrence/recurrence.dart';
export 'package:urgency/urgency.dart';

export 'src/entities/household_task.dart';
export 'src/entities/task_category.dart';
export 'src/errors/task_list_exception.dart';
export 'src/list/task_list_view.dart';
export 'src/repositories/task_list_repository.dart';
export 'src/sync/task_list_codec.dart';
export 'src/sync/task_list_resolver.dart';
export 'src/sync/task_list_sync_participant.dart';
export 'src/sync/task_list_sync_store.dart';
export 'src/task_validator.dart';
