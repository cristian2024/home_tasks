/// Fuente de tiempo de la aplicación. Siempre devuelve instantes en UTC.
/// Se inyecta para poder fijar el tiempo en los tests.
abstract interface class Clock {
  DateTime nowUtc();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Reloj de valor fijo para tests.
class FixedClock implements Clock {
  FixedClock(DateTime now) : _now = now.toUtc();

  DateTime _now;

  void advance(Duration duration) => _now = _now.add(duration);

  @override
  DateTime nowUtc() => _now;
}
