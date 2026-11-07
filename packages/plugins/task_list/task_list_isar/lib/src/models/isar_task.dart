import 'package:storage_isar/adapter.dart';
import 'package:task_list_domain/task_list_domain.dart';

part 'isar_task.g.dart';

@collection
class IsarTask {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID v4

  late String title;

  @Enumerated(EnumType.name)
  late Urgency urgency;

  @Enumerated(EnumType.name)
  late TaskStatus status;

  /// Índice multiEntry: permite buscar las tareas de una categoría al borrarla.
  @Index(type: IndexType.value)
  List<String> categoryIds = <String>[];

  /// Día límite como medianoche UTC; `null` si no tiene.
  DateTime? dueDate;

  /// Recurrencia: los dos `null` si no se repite.
  int? recurrenceMinDays;
  int? recurrenceMaxDays;

  DateTime? lastDoneAt;
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Borrado lógico: `null` si está activa.
  DateTime? deletedAt;
}
