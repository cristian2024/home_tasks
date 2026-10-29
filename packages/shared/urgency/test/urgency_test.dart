import 'package:test/test.dart';
import 'package:urgency/urgency.dart';

void main() {
  test('los niveles van de más a menos urgente', () {
    expect(Urgency.values, <Urgency>[Urgency.immediate, Urgency.high, Urgency.normal, Urgency.low]);
  });

  test('ordenar pone primero lo más urgente', () {
    final List<Urgency> sorted = <Urgency>[Urgency.low, Urgency.immediate, Urgency.normal, Urgency.high]..sort();

    expect(sorted, Urgency.values);
  });

  test('solo inmediata y alta son urgentes', () {
    expect(Urgency.values.where((Urgency urgency) => urgency.isUrgent), <Urgency>[Urgency.immediate, Urgency.high]);
  });

  test('isMoreUrgentThan compara niveles', () {
    expect(Urgency.immediate.isMoreUrgentThan(Urgency.high), isTrue);
    expect(Urgency.normal.isMoreUrgentThan(Urgency.normal), isFalse);
    expect(Urgency.low.isMoreUrgentThan(Urgency.normal), isFalse);
  });

  test('el valor por defecto es normal', () {
    expect(Urgency.defaultValue, Urgency.normal);
  });
}
