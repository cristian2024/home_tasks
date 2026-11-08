import 'clock.dart';

/// Días de calendario, sin hora: una fecha límite, «hoy», «mañana».
///
/// Un día se representa como la medianoche UTC de esa fecha (`2026-11-12
/// 00:00Z`), así se guarda en UTC como el resto de fechas sin que la zona
/// horaria lo mueva. Para comparar con un instante, primero se convierte al
/// día local con [localDayOf].
abstract final class CalendarDay {
  /// El día de [date], sin la hora: medianoche UTC de su año, mes y día.
  static DateTime of(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  /// El día local en que cae [instant] (p. ej. la hora de un [Clock]).
  static DateTime localDayOf(DateTime instant) => of(instant.toLocal());

  /// Días de [from] a [to], ambos días de calendario. Negativo si [to] es antes.
  static int daysBetween(DateTime from, DateTime to) => of(to).difference(of(from)).inHours ~/ Duration.hoursPerDay;

  /// Cómo nombrar [day] respecto a [today]: «Ayer», «Hoy», «Mañana» o su fecha.
  static RelativeDay relativeTo(DateTime day, {required DateTime today}) => switch (daysBetween(today, day)) {
        -1 => RelativeDay.yesterday,
        0 => RelativeDay.today,
        1 => RelativeDay.tomorrow,
        _ => RelativeDay.other,
      };
}

/// Cómo se nombra un día respecto a hoy. Solo «Ayer», «Hoy» y «Mañana» tienen
/// nombre; el resto se muestra con su fecha. Los textos los pone quien lo usa.
enum RelativeDay { yesterday, today, tomorrow, other }

/// El día local de hoy según el reloj.
extension ClockToday on Clock {
  DateTime today() => CalendarDay.localDayOf(nowUtc());
}
