import 'package:core_utils/core_utils.dart';

import 'hlc.dart';
import 'hlc_exception.dart';

/// Reloj lógico híbrido de un dispositivo. Cada marca que genera es mayor que
/// todas las anteriores, las propias y las recibidas con [receive].
///
/// Quien lo use guarda [last] y lo pasa al crearlo de nuevo, para que el orden
/// se mantenga entre reinicios aunque el reloj del sistema retroceda.
class HlcClock {
  HlcClock({
    required this.deviceId,
    required Clock clock,
    Hlc? last,
    this.maxDrift = defaultMaxDrift,
  })  : _clock = clock,
        _last = last ?? Hlc(wallTime: 0, counter: 0, deviceId: deviceId);

  /// Cuánto puede ir por delante una marca recibida antes de rechazarla.
  static const Duration defaultMaxDrift = Duration(minutes: 5);

  final String deviceId;
  final Duration maxDrift;
  final Clock _clock;
  Hlc _last;

  /// Última marca generada (o la inicial, si aún no generó ninguna).
  Hlc get last => _last;

  /// Marca para un cambio local.
  ///
  /// Lanza [HlcCounterOverflowException] si se agota el contador.
  Hlc now() {
    final int physical = _physicalTime();
    if (physical > _last.wallTime) {
      return _advance(physical, 0);
    }
    return _advance(_last.wallTime, _last.counter + 1);
  }

  /// Avanza el reloj con una marca recibida de otro dispositivo y devuelve la
  /// marca local resultante, mayor que [remote] y que [last].
  ///
  /// Lanza [HlcClockDriftException] si [remote] va por delante del reloj del
  /// sistema más de [maxDrift] (el reloj no cambia), y
  /// [HlcCounterOverflowException] si se agota el contador.
  Hlc receive(Hlc remote) {
    final int physical = _physicalTime();
    final Duration drift = Duration(milliseconds: remote.wallTime - physical);
    if (drift > maxDrift) {
      throw HlcClockDriftException(remote: remote, drift: drift, maxDrift: maxDrift);
    }
    final int localWall = _last.wallTime;
    final int wall = <int>[physical, localWall, remote.wallTime].reduce(_max);
    if (wall == localWall && wall == remote.wallTime) {
      return _advance(wall, _max(_last.counter, remote.counter) + 1);
    }
    if (wall == localWall) {
      return _advance(wall, _last.counter + 1);
    }
    if (wall == remote.wallTime) {
      return _advance(wall, remote.counter + 1);
    }
    return _advance(wall, 0);
  }

  int _physicalTime() => _clock.nowUtc().millisecondsSinceEpoch;

  Hlc _advance(int wallTime, int counter) {
    if (counter > Hlc.maxCounter) {
      throw HlcCounterOverflowException(wallTime);
    }
    return _last = Hlc(wallTime: wallTime, counter: counter, deviceId: deviceId);
  }

  static int _max(int a, int b) => a > b ? a : b;
}
