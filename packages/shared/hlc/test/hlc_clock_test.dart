import 'package:core_utils/core_utils.dart';
import 'package:hlc/hlc.dart';
import 'package:test/test.dart';

void main() {
  final DateTime start = DateTime.utc(2026, 10, 30, 12);
  final int startMs = start.millisecondsSinceEpoch;
  late FixedClock clock;

  Hlc hlc(int wallTime, int counter, [String deviceId = 'local']) =>
      Hlc(wallTime: wallTime, counter: counter, deviceId: deviceId);

  HlcClock localClock({Hlc? last, Duration maxDrift = HlcClock.defaultMaxDrift}) =>
      HlcClock(deviceId: 'local', clock: clock, last: last, maxDrift: maxDrift);

  setUp(() => clock = FixedClock(start));

  group('now', () {
    test('usa el tiempo del sistema cuando avanza', () {
      final HlcClock hlcClock = localClock();

      expect(hlcClock.last, hlc(0, 0));
      expect(hlcClock.now(), hlc(startMs, 0));
      clock.advance(const Duration(milliseconds: 5));
      expect(hlcClock.now(), hlc(startMs + 5, 0));
      expect(hlcClock.last, hlc(startMs + 5, 0));
    });

    test('sube el contador en el mismo milisegundo', () {
      final HlcClock hlcClock = localClock();

      expect(<Hlc>[hlcClock.now(), hlcClock.now(), hlcClock.now()], <Hlc>[
        hlc(startMs, 0),
        hlc(startMs, 1),
        hlc(startMs, 2),
      ]);
    });

    test('nunca retrocede aunque retroceda el reloj del sistema', () {
      final HlcClock hlcClock = localClock(last: hlc(startMs + 1000, 7));

      expect(hlcClock.now(), hlc(startMs + 1000, 8));
    });

    test('continúa desde la última marca guardada, con su propio deviceId', () {
      final HlcClock hlcClock = localClock(last: hlc(startMs, 3, 'otro'));

      expect(hlcClock.now(), hlc(startMs, 4));
    });

    test('lanza HlcCounterOverflowException al agotar el contador', () {
      final HlcClock hlcClock = localClock(last: hlc(startMs, Hlc.maxCounter));

      expect(
        hlcClock.now,
        throwsA(isA<HlcCounterOverflowException>()
            .having((HlcCounterOverflowException e) => e.wallTime, 'wallTime', startMs)
            .having((HlcCounterOverflowException e) => e.toString(), 'toString', contains('$startMs'))),
      );
      expect(hlcClock.last, hlc(startMs, Hlc.maxCounter));
    });
  });

  group('receive', () {
    test('con el reloj del sistema por delante, usa su tiempo y el contador a cero', () {
      final HlcClock hlcClock = localClock(last: hlc(startMs - 10, 4));

      expect(hlcClock.receive(hlc(startMs - 5, 9, 'remoto')), hlc(startMs, 0));
    });

    test('con la marca local por delante, sube el contador local', () {
      final HlcClock hlcClock = localClock(last: hlc(startMs + 100, 4));

      expect(hlcClock.receive(hlc(startMs + 50, 9, 'remoto')), hlc(startMs + 100, 5));
    });

    test('con la marca remota por delante, adopta su tiempo y sube su contador', () {
      final HlcClock hlcClock = localClock(last: hlc(startMs, 4));
      final Hlc remote = hlc(startMs + 100, 9, 'remoto');

      final Hlc received = hlcClock.receive(remote);

      expect(received, hlc(startMs + 100, 10));
      expect(received.isAfter(remote), isTrue);
      expect(hlcClock.now(), hlc(startMs + 100, 11));
    });

    test('con el mismo tiempo local y remoto, sube el mayor de los contadores', () {
      final HlcClock hlcClock = localClock(last: hlc(startMs + 100, 4));

      expect(hlcClock.receive(hlc(startMs + 100, 9, 'remoto')), hlc(startMs + 100, 10));
      expect(hlcClock.receive(hlc(startMs + 100, 2, 'remoto')), hlc(startMs + 100, 11));
    });

    test('lanza HlcClockDriftException si la marca remota va demasiado por delante', () {
      final HlcClock hlcClock = localClock(last: hlc(startMs, 4), maxDrift: const Duration(seconds: 1));
      final Hlc remote = hlc(startMs + 1001, 0, 'remoto');

      expect(
        () => hlcClock.receive(remote),
        throwsA(isA<HlcClockDriftException>()
            .having((HlcClockDriftException e) => e.remote, 'remote', remote)
            .having((HlcClockDriftException e) => e.drift, 'drift', const Duration(milliseconds: 1001))
            .having((HlcClockDriftException e) => e.maxDrift, 'maxDrift', const Duration(seconds: 1))
            .having((HlcClockDriftException e) => e.toString(), 'toString', contains(remote.encode()))),
      );
      expect(hlcClock.last, hlc(startMs, 4));
      expect(hlcClock.receive(hlc(startMs + 1000, 0, 'remoto')), hlc(startMs + 1000, 1));
    });

    test('lanza HlcCounterOverflowException si el contador remoto está agotado', () {
      final HlcClock hlcClock = localClock();

      expect(
        () => hlcClock.receive(hlc(startMs, Hlc.maxCounter, 'remoto')),
        throwsA(isA<HlcCounterOverflowException>()),
      );
    });
  });

  test('las marcas de dos dispositivos que se comunican respetan la causalidad', () {
    final FixedClock behind = FixedClock(start.subtract(const Duration(minutes: 1)));
    final HlcClock a = localClock();
    final HlcClock b = HlcClock(deviceId: 'b', clock: behind);

    final Hlc sentByA = a.now();
    final Hlc receivedByB = b.receive(sentByA);
    final Hlc nextInB = b.now();
    final Hlc backInA = a.receive(nextInB);

    expect(<Hlc>[sentByA, receivedByB, nextInB, backInA], orderedEquals(<Hlc>[sentByA, receivedByB, nextInB, backInA]..sort()));
    expect(<Hlc>{sentByA, receivedByB, nextInB, backInA}, hasLength(4));
  });
}
