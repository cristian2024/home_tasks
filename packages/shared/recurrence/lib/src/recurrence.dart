import 'package:equatable/equatable.dart';

/// En qué punto está algo recurrente respecto a su ventana.
enum RecurrenceStatus {
  /// Aún no toca: la ventana no se ha abierto.
  waiting,

  /// Toca: la ventana está abierta.
  due,

  /// Atrasado: la ventana ya se cerró.
  overdue,
}

/// Cada cuánto se repite algo, de forma aproximada: entre [minDays] y
/// [maxDays] días después de la última vez (los huevos, cada 8 a 15 días).
/// Con [Recurrence.fixed] los dos valores coinciden.
class Recurrence extends Equatable {
  /// Lanza [ArgumentError] si no se cumple `1 <= minDays <= maxDays <= 365`.
  Recurrence.between(this.minDays, this.maxDays) {
    if (minDays < 1 || minDays > maxDays || maxDays > maxAllowedDays) {
      throw ArgumentError('Se esperaba 1 <= minDays <= maxDays <= $maxAllowedDays: $minDays..$maxDays');
    }
  }

  /// Cada [days] días exactos.
  Recurrence.fixed(int days) : this.between(days, days);

  /// Máximo de días que admite una recurrencia.
  static const int maxAllowedDays = 365;

  final int minDays;
  final int maxDays;

  bool get isFixed => minDays == maxDays;

  /// Ventana siguiente a [lastDone]: se abre a los [minDays] días y se cierra
  /// al terminar el día [maxDays] (el último día cuenta entero). En UTC.
  RecurrenceWindow windowAfter(DateTime lastDone) {
    final DateTime start = lastDone.toUtc();
    return RecurrenceWindow(
      opensAt: start.add(Duration(days: minDays)),
      closesAt: start.add(Duration(days: maxDays + 1)),
    );
  }

  /// Estado en [now]. Si nunca se hizo ([lastDone] es `null`), toca.
  RecurrenceStatus statusAt(DateTime now, {required DateTime? lastDone}) {
    if (lastDone == null) {
      return RecurrenceStatus.due;
    }
    return windowAfter(lastDone).statusAt(now);
  }

  @override
  List<Object?> get props => <Object?>[minDays, maxDays];
}

/// Intervalo en que toca repetir algo: desde [opensAt] (incluido) hasta
/// [closesAt] (excluido). En UTC.
class RecurrenceWindow extends Equatable {
  RecurrenceWindow({required DateTime opensAt, required DateTime closesAt})
      : opensAt = opensAt.toUtc(),
        closesAt = closesAt.toUtc();

  final DateTime opensAt;
  final DateTime closesAt;

  RecurrenceStatus statusAt(DateTime now) {
    final DateTime instant = now.toUtc();
    if (instant.isBefore(opensAt)) {
      return RecurrenceStatus.waiting;
    }
    return instant.isBefore(closesAt) ? RecurrenceStatus.due : RecurrenceStatus.overdue;
  }

  @override
  List<Object?> get props => <Object?>[opensAt, closesAt];
}
