import 'package:core_utils/core_utils.dart';
import 'package:test/test.dart';

void main() {
  group('UuidV4Generator', () {
    test('genera UUID v4 canónicos y distintos', () {
      const UuidV4Generator generator = UuidV4Generator();
      final Set<String> ids = <String>{for (int i = 0; i < 100; i++) generator.newId()};

      expect(ids, hasLength(100));
      expect(ids.every(isUuidV4), isTrue);
    });
  });

  group('isUuidV4', () {
    test('rechaza otras versiones y formatos', () {
      expect(isUuidV4('f47ac10b-58cc-4372-a567-0e02b2c3d479'), isTrue);
      expect(isUuidV4('f47ac10b-58cc-1372-a567-0e02b2c3d479'), isFalse); // v1
      expect(isUuidV4('F47AC10B-58CC-4372-A567-0E02B2C3D479'), isFalse);
      expect(isUuidV4('42'), isFalse);
    });
  });

  group('Clock', () {
    test('SystemClock devuelve UTC', () {
      expect(const SystemClock().nowUtc().isUtc, isTrue);
    });

    test('FixedClock normaliza a UTC y avanza', () {
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 21, 14, 30));
      clock.advance(const Duration(minutes: 30));

      expect(clock.nowUtc(), DateTime.utc(2026, 10, 21, 15));
      expect(FixedClock(DateTime(2026)).nowUtc().isUtc, isTrue);
    });
  });
}
