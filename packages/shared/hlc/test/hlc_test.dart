import 'package:hlc/hlc.dart';
import 'package:test/test.dart';

void main() {
  Hlc hlc(int wallTime, int counter, [String deviceId = 'a']) =>
      Hlc(wallTime: wallTime, counter: counter, deviceId: deviceId);

  group('Hlc', () {
    test('rechaza valores fuera de rango y un deviceId vacío', () {
      expect(() => hlc(-1, 0), throwsArgumentError);
      expect(() => hlc(Hlc.maxWallTime + 1, 0), throwsArgumentError);
      expect(() => hlc(0, -1), throwsArgumentError);
      expect(() => hlc(0, Hlc.maxCounter + 1), throwsArgumentError);
      expect(() => hlc(0, 0, ''), throwsArgumentError);
      expect(hlc(Hlc.maxWallTime, Hlc.maxCounter).counter, Hlc.maxCounter);
    });

    test('ordena por tiempo de pared, luego contador y luego dispositivo', () {
      final List<Hlc> sorted = <Hlc>[hlc(2, 0), hlc(1, 1, 'b'), hlc(1, 1, 'a'), hlc(1, 0, 'z')]..sort();

      expect(sorted, <Hlc>[hlc(1, 0, 'z'), hlc(1, 1, 'a'), hlc(1, 1, 'b'), hlc(2, 0)]);
      expect(hlc(1, 0).isBefore(hlc(1, 1)), isTrue);
      expect(hlc(1, 1).isAfter(hlc(1, 0)), isTrue);
      expect(hlc(1, 0).isAfter(hlc(1, 0)), isFalse);
      expect(hlc(1, 0).compareTo(hlc(1, 0)), 0);
    });

    test('igualdad por valor', () {
      expect(hlc(1, 2, 'a'), hlc(1, 2, 'a'));
      expect(hlc(1, 2, 'a'), isNot(hlc(1, 2, 'b')));
    });

    test('fromDateTime y dateTime trabajan en UTC', () {
      final DateTime time = DateTime.utc(2026, 10, 30, 12, 30);
      final Hlc fromLocal = Hlc.fromDateTime(time.toLocal(), deviceId: 'a');

      expect(fromLocal, hlc(time.millisecondsSinceEpoch, 0));
      expect(fromLocal.dateTime, time);
      expect(fromLocal.dateTime.isUtc, isTrue);
      expect(Hlc.fromDateTime(time, deviceId: 'a', counter: 3).counter, 3);
    });

    test('encode y parse son inversos, también con un deviceId con guiones', () {
      final Hlc value = hlc(1761827400000, 42, '3f2b-11aa-9c');

      expect(value.encode(), '001761827400000-00042-3f2b-11aa-9c');
      expect(value.toString(), value.encode());
      expect(Hlc.parse(value.encode()), value);
    });

    test('ordenar los textos de encode da el mismo orden que compareTo', () {
      final List<Hlc> values = <Hlc>[hlc(10, 0), hlc(9, 65535), hlc(9, 2, 'b'), hlc(9, 2, 'a'), hlc(100, 0)];
      final List<String> byText = values.map((Hlc value) => value.encode()).toList()..sort();

      expect(byText.map(Hlc.parse).toList(), List<Hlc>.of(values)..sort());
    });

    test('parse rechaza lo que no es un HLC', () {
      for (final String value in <String>['', 'abc', '1-2-a', '001761827400000-00042-', '001761827400000-0042-a']) {
        expect(() => Hlc.parse(value), throwsFormatException, reason: value);
      }
    });
  });
}
