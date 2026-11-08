import 'package:core_utils/core_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:recurrence/recurrence.dart';
import 'package:urgency/urgency.dart';

/// Estado guardado de una tarea. Una tarea que se repite nunca queda hecha:
/// al completarla vuelve a esperar su ventana.
enum TaskStatus { pending, done }

/// Estado que se muestra, derivado del guardado, la fecha, la recurrencia y la
/// hora ([HouseholdTask.stateAt]).
enum TaskState {
  /// Su fecha pasó, o es repetida y su ventana se cerró sin hacerla.
  overdue,

  /// Es para hoy, o es repetida y su ventana está abierta (o nunca se hizo).
  today,

  /// Su fecha es posterior a hoy.
  upcoming,

  /// No tiene fecha ni se repite.
  noDate,

  /// Es repetida y su ventana aún no se abre.
  waiting,

  /// Hecha. Solo las que no se repiten.
  done;

  /// Si está en lo que hay que hacer: ni en espera ni hecha.
  bool get isToDo => this != TaskState.waiting && this != TaskState.done;
}

/// Una tarea de la casa.
class HouseholdTask extends Equatable {
  /// [dueDate] y [recurrence] se excluyen: una tarea que se repite no tiene
  /// fecha propia.
  const HouseholdTask({
    required this.id,
    required this.title,
    required this.urgency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.categoryIds = const <String>[],
    this.dueDate,
    this.recurrence,
    this.lastDoneAt,
  }) : assert(dueDate == null || recurrence == null, 'Una tarea que se repite no tiene fecha');

  final String id; // UUID v4, inmutable
  final String title;
  final Urgency urgency;
  final TaskStatus status;

  /// IDs de sus categorías, sin repetir. Cuál va primero lo decide el orden
  /// de las categorías, no esta lista.
  final List<String> categoryIds;

  /// Día límite, como medianoche UTC de esa fecha ([CalendarDay]); `null` si
  /// no tiene.
  final DateTime? dueDate;

  /// `null` si no se repite.
  final Recurrence? recurrence;

  /// Última vez que se hizo (UTC); `null` si nunca.
  final DateTime? lastDoneAt;

  final DateTime createdAt; // UTC, inmutable
  final DateTime updatedAt; // UTC, se actualiza en cada escritura

  bool get isRecurring => recurrence != null;

  /// Estado en [now]. [today] es el día local de [now] ([Clock.today]): la
  /// fecha límite se compara con él, no con la hora UTC.
  TaskState stateAt(DateTime now, {required DateTime today}) {
    final Recurrence? recurrence = this.recurrence;
    if (recurrence != null) {
      return switch (recurrence.statusAt(now, lastDone: lastDoneAt)) {
        RecurrenceStatus.waiting => TaskState.waiting,
        RecurrenceStatus.due => TaskState.today,
        RecurrenceStatus.overdue => TaskState.overdue,
      };
    }
    if (status == TaskStatus.done) {
      return TaskState.done;
    }
    final DateTime? dueDate = this.dueDate;
    if (dueDate == null) {
      return TaskState.noDate;
    }
    return switch (CalendarDay.daysBetween(today, dueDate)) {
      < 0 => TaskState.overdue,
      0 => TaskState.today,
      _ => TaskState.upcoming,
    };
  }

  /// Cuándo vuelve una tarea repetida que ya se hizo: el día local en que se
  /// abre su ventana. `null` si no se repite o nunca se hizo.
  DateTime? get returnsOn {
    final Recurrence? recurrence = this.recurrence;
    final DateTime? lastDoneAt = this.lastDoneAt;
    if (recurrence == null || lastDoneAt == null) {
      return null;
    }
    return CalendarDay.localDayOf(recurrence.windowAfter(lastDoneAt).opensAt);
  }

  HouseholdTask copyWith({
    String? title,
    Urgency? urgency,
    TaskStatus? status,
    List<String>? categoryIds,
    DateTime? Function()? dueDate,
    Recurrence? Function()? recurrence,
    DateTime? Function()? lastDoneAt,
    DateTime? updatedAt,
  }) {
    return HouseholdTask(
      id: id,
      title: title ?? this.title,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      categoryIds: categoryIds ?? this.categoryIds,
      dueDate: dueDate == null ? this.dueDate : dueDate(),
      recurrence: recurrence == null ? this.recurrence : recurrence(),
      lastDoneAt: lastDoneAt == null ? this.lastDoneAt : lastDoneAt(),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        urgency,
        status,
        categoryIds,
        dueDate,
        recurrence,
        lastDoneAt,
        createdAt,
        updatedAt,
      ];

  @override
  bool get stringify => true;
}
