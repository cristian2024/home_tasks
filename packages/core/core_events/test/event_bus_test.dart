import 'package:core_events/core_events.dart';
import 'package:test/test.dart';

class OtherEvent extends CrossPluginEvent {}

void main() {
  late EventBus bus;

  setUp(() => bus = EventBus());
  tearDown(() => bus.dispose());

  test('on<T> solo emite eventos del tipo pedido', () async {
    final received = bus.on<ItemCreatedCrossEvent>().toList();

    bus
      ..publish(ItemCreatedCrossEvent(itemId: '1', itemName: 'Caja A'))
      ..publish(OtherEvent())
      ..publish(ItemCreatedCrossEvent(itemId: '2', itemName: 'Cama'));
    await bus.dispose();

    expect((await received).map((e) => e.itemId), ['1', '2']);
  });

  test('on<CrossPluginEvent> recibe todos los eventos', () async {
    final received = bus.on<CrossPluginEvent>().toList();

    bus
      ..publish(OtherEvent())
      ..publish(ItemCreatedCrossEvent(itemId: '1', itemName: 'Caja A'));
    await bus.dispose();

    expect(await received, hasLength(2));
  });

  test('emittedAt está en UTC', () {
    expect(OtherEvent().emittedAt.isUtc, isTrue);
  });

  test('publicar tras dispose no lanza', () async {
    await bus.dispose();

    expect(() => bus.publish(OtherEvent()), returnsNormally);
  });
}
