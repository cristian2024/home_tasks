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

  group('CalendarDay', () {
    test('quita la hora y deja la medianoche UTC', () {
      expect(CalendarDay.of(DateTime(2026, 11, 12, 23, 59)), DateTime.utc(2026, 11, 12));
      expect(CalendarDay.of(DateTime.utc(2026, 11, 12, 1)), DateTime.utc(2026, 11, 12));
    });

    test('el día local de un instante usa la zona del dispositivo', () {
      final DateTime instant = DateTime.utc(2026, 11, 12, 3, 30);
      final DateTime local = instant.toLocal();

      expect(CalendarDay.localDayOf(instant), DateTime.utc(local.year, local.month, local.day));
    });

    test('cuenta días entre fechas, también con cambios de hora', () {
      expect(CalendarDay.daysBetween(DateTime.utc(2026, 11, 12), DateTime.utc(2026, 11, 20)), 8);
      expect(CalendarDay.daysBetween(DateTime.utc(2026, 11, 20), DateTime.utc(2026, 11, 12)), -8);
      expect(CalendarDay.daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    });

    test('nombra ayer, hoy y mañana', () {
      final DateTime today = DateTime.utc(2026, 11, 7);

      expect(CalendarDay.relativeTo(DateTime.utc(2026, 11, 6), today: today), RelativeDay.yesterday);
      expect(CalendarDay.relativeTo(DateTime.utc(2026, 11, 7), today: today), RelativeDay.today);
      expect(CalendarDay.relativeTo(DateTime.utc(2026, 11, 8), today: today), RelativeDay.tomorrow);
      expect(CalendarDay.relativeTo(DateTime.utc(2026, 11, 12), today: today), RelativeDay.other);
      expect(CalendarDay.relativeTo(DateTime.utc(2026, 11, 5), today: today), RelativeDay.other);
    });

    test('Clock.today es el día local del reloj', () {
      final FixedClock clock = FixedClock(DateTime.utc(2026, 11, 7, 12));

      expect(clock.today(), CalendarDay.localDayOf(DateTime.utc(2026, 11, 7, 12)));
    });
  });
}
