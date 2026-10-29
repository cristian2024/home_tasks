import 'package:recurrence/recurrence.dart';
import 'package:test/test.dart';

void main() {
  final DateTime lastDone = DateTime.utc(2026, 10, 1, 18);

  group('Recurrence', () {
    test('between guarda el mínimo y el máximo', () {
      final Recurrence eggs = Recurrence.between(8, 15);

      expect(eggs.minDays, 8);
      expect(eggs.maxDays, 15);
      expect(eggs.isFixed, isFalse);
    });

    test('fixed usa el mismo valor como mínimo y máximo', () {
      expect(Recurrence.fixed(7), Recurrence.between(7, 7));
      expect(Recurrence.fixed(7).isFixed, isTrue);
    });

    test('rechaza valores fuera de 1..365 o con el mínimo mayor que el máximo', () {
      expect(() => Recurrence.between(0, 5), throwsArgumentError);
      expect(() => Recurrence.between(6, 5), throwsArgumentError);
      expect(() => Recurrence.between(1, 366), throwsArgumentError);
      expect(() => Recurrence.fixed(0), throwsArgumentError);
      expect(Recurrence.between(1, Recurrence.maxAllowedDays).maxDays, 365);
    });

    test('igualdad por valor', () {
      expect(Recurrence.between(8, 15), Recurrence.between(8, 15));
      expect(Recurrence.between(8, 15), isNot(Recurrence.between(8, 14)));
    });

    test('windowAfter se abre a los minDays y se cierra al terminar el día maxDays', () {
      expect(
        Recurrence.between(8, 15).windowAfter(lastDone),
        RecurrenceWindow(opensAt: DateTime.utc(2026, 10, 9, 18), closesAt: DateTime.utc(2026, 10, 17, 18)),
      );
    });

    test('windowAfter trabaja en UTC aunque reciba una hora local', () {
      final RecurrenceWindow window = Recurrence.fixed(1).windowAfter(lastDone.toLocal());

      expect(window.opensAt.isUtc, isTrue);
      expect(window.opensAt, DateTime.utc(2026, 10, 2, 18));
    });

    group('statusAt', () {
      final Recurrence eggs = Recurrence.between(8, 15);

      test('si nunca se hizo, toca', () {
        expect(eggs.statusAt(lastDone, lastDone: null), RecurrenceStatus.due);
      });

      test('antes de abrirse la ventana está en espera', () {
        expect(eggs.statusAt(DateTime.utc(2026, 10, 9, 17, 59), lastDone: lastDone), RecurrenceStatus.waiting);
      });

      test('desde que se abre hasta que se cierra, toca', () {
        expect(eggs.statusAt(DateTime.utc(2026, 10, 9, 18), lastDone: lastDone), RecurrenceStatus.due);
        expect(eggs.statusAt(DateTime.utc(2026, 10, 17, 17, 59), lastDone: lastDone), RecurrenceStatus.due);
      });

      test('desde que se cierra está atrasado', () {
        expect(eggs.statusAt(DateTime.utc(2026, 10, 17, 18), lastDone: lastDone), RecurrenceStatus.overdue);
      });

      test('una recurrencia fija toca durante su día', () {
        final Recurrence weekly = Recurrence.fixed(7);

        expect(weekly.statusAt(DateTime.utc(2026, 10, 8, 17), lastDone: lastDone), RecurrenceStatus.waiting);
        expect(weekly.statusAt(DateTime.utc(2026, 10, 8, 18), lastDone: lastDone), RecurrenceStatus.due);
        expect(weekly.statusAt(DateTime.utc(2026, 10, 9, 17), lastDone: lastDone), RecurrenceStatus.due);
        expect(weekly.statusAt(DateTime.utc(2026, 10, 9, 18), lastDone: lastDone), RecurrenceStatus.overdue);
      });
    });
  });

  group('RecurrenceWindow', () {
    test('guarda los instantes en UTC y compara una hora local correctamente', () {
      final DateTime opens = DateTime.utc(2026, 10, 9);
      final RecurrenceWindow window = RecurrenceWindow(opensAt: opens.toLocal(), closesAt: DateTime.utc(2026, 10, 10));

      expect(window.opensAt, opens);
      expect(window.opensAt.isUtc, isTrue);
      expect(window.statusAt(opens.toLocal()), RecurrenceStatus.due);
    });
  });
}
