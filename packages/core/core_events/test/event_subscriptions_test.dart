import 'dart:async';

import 'package:core_events/core_events.dart';
import 'package:test/test.dart';

class _Event extends CrossPluginEvent {
  _Event(this.value) : super(emittedAt: DateTime.utc(2026, 10, 29));

  final int value;
}

void main() {
  late EventBus bus;
  late EventSubscriptions subscriptions;

  setUp(() {
    bus = EventBus();
    subscriptions = EventSubscriptions();
  });
  tearDown(() => bus.dispose());

  test('listen recibe los eventos hasta cancelAll', () async {
    final List<int> received = <int>[];
    subscriptions.listen<_Event>(bus, (_Event event) => received.add(event.value));

    bus.publish(_Event(1));
    await Future<void>.delayed(Duration.zero);
    subscriptions.cancelAll();
    bus.publish(_Event(2));
    await Future<void>.delayed(Duration.zero);

    expect(received, <int>[1]);
    expect(subscriptions.isCancelled, isTrue);
  });

  test('cancelAll cancela también las suscripciones añadidas con add', () async {
    bool cancelled = false;
    final StreamController<int> controller = StreamController<int>(onCancel: () => cancelled = true);
    subscriptions.add(controller.stream.listen((_) {}));

    subscriptions.cancelAll();
    await Future<void>.delayed(Duration.zero);

    expect(cancelled, isTrue);
    await controller.close();
  });

  test('lo que se añade después de cancelAll se cancela al momento', () async {
    final List<int> received = <int>[];
    subscriptions
      ..cancelAll()
      ..listen<_Event>(bus, (_Event event) => received.add(event.value));

    bus.publish(_Event(1));
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
  });

  test('cancelAll no espera a que terminen las cancelaciones', () {
    final Completer<void> neverCompletes = Completer<void>();
    final StreamController<int> controller = StreamController<int>(onCancel: () => neverCompletes.future);
    subscriptions.add(controller.stream.listen((_) {}));

    expect(subscriptions.cancelAll, returnsNormally);
    unawaited(controller.close());
  });
}
