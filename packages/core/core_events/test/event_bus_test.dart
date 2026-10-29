import 'package:core_events/core_events.dart';
import 'package:core_events/testing.dart';
import 'package:test/test.dart';

class _Event extends CrossPluginEvent {
  _Event({super.emittedAt});
}

void main() {
  eventBusContract('StreamEventBus', create: StreamEventBus.new);
  eventBusContract('EventBus()', create: EventBus.new);
  eventBusContract('RecordingEventBus', create: RecordingEventBus.new);

  group('RecordingEventBus', () {
    test('guarda lo publicado y filtra por tipo', () async {
      final RecordingEventBus bus = RecordingEventBus();
      final ItemCreatedCrossEvent created = ItemCreatedCrossEvent(itemId: '1', itemName: 'Caja A');
      final _Event other = _Event();

      bus
        ..publish(created)
        ..publish(other);
      await bus.dispose();

      expect(bus.published, <CrossPluginEvent>[created, other]);
      expect(bus.publishedOf<ItemCreatedCrossEvent>(), <ItemCreatedCrossEvent>[created]);
    });
  });

  group('CrossPluginEvent', () {
    test('sin emittedAt usa la hora actual en UTC', () {
      final DateTime before = DateTime.now().toUtc();
      final _Event event = _Event();

      expect(event.emittedAt.isUtc, isTrue);
      expect(event.emittedAt.isBefore(before), isFalse);
    });

    test('convierte a UTC el emittedAt recibido', () {
      final DateTime local = DateTime(2026, 10, 28, 9);

      expect(_Event(emittedAt: local).emittedAt, local.toUtc());
      expect(ItemCreatedCrossEvent(itemId: '1', itemName: 'A', emittedAt: local).emittedAt.isUtc, isTrue);
    });
  });
}
