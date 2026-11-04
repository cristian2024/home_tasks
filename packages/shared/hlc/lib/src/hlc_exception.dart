import 'hlc.dart';

/// Errores del reloj lógico híbrido.
sealed class HlcException implements Exception {
  const HlcException();
}

/// Se agotó el contador de un milisegundo: más de [Hlc.maxCounter] marcas sin
/// que avance el tiempo de pared.
final class HlcCounterOverflowException extends HlcException {
  const HlcCounterOverflowException(this.wallTime);

  final int wallTime;

  @override
  String toString() => 'HlcCounterOverflowException: contador agotado en $wallTime';
}

/// Una marca recibida va por delante del reloj local más de lo admitido:
/// el reloj del otro dispositivo está mal y no se adopta su tiempo.
final class HlcClockDriftException extends HlcException {
  const HlcClockDriftException({required this.remote, required this.drift, required this.maxDrift});

  final Hlc remote;
  final Duration drift;
  final Duration maxDrift;

  @override
  String toString() => 'HlcClockDriftException: $remote va $drift por delante (máximo $maxDrift)';
}
