import 'dart:async';

import 'package:test/test.dart';

import '../cross_plugin_event.dart';
import '../event_bus.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 29);

class _EventA extends CrossPluginEvent {
  _EventA(this.value, {DateTime? emittedAt}) : super(emittedAt: emittedAt ?? _t0);

  final int value;
}

class _EventB extends CrossPluginEvent {
  _EventB() : super(emittedAt: _t0);
}

class _SubEventA extends _EventA {
  _SubEventA(super.value);
}

/// Tests de contrato de [EventBus]. Toda implementación debe pasarlos.
///
/// [create] devuelve un bus nuevo para cada test; el contrato lo libera.
///
/// ```dart
/// eventBusContract('StreamEventBus', create: StreamEventBus.new);
/// ```
void eventBusContract(String implementation, {required EventBus Function() create}) {
  group('EventBus ($implementation)', () {
    late EventBus bus;

    setUp(() => bus = create());
    tearDown(() => bus.dispose());

    test('on<T> solo emite eventos del tipo pedido y sus subtipos, en orden', () async {
      final Future<List<_EventA>> received = bus.on<_EventA>().toList();

      bus
        ..publish(_EventA(1))
        ..publish(_EventB())
        ..publish(_SubEventA(2));
      await bus.dispose();

      expect((await received).map((_EventA event) => event.value), <int>[1, 2]);
    });

    test('on<CrossPluginEvent> recibe todos los eventos', () async {
      final Future<List<CrossPluginEvent>> received = bus.on<CrossPluginEvent>().toList();

      bus
        ..publish(_EventB())
        ..publish(_EventA(1));
      await bus.dispose();

      expect(await received, hasLength(2));
    });

    test('cada suscriptor recibe el mismo evento', () async {
      final Future<_EventA> first = bus.on<_EventA>().first;
      final Future<_EventA> second = bus.on<_EventA>().first;
      final _EventA event = _EventA(1);

      bus.publish(event);

      expect(await first, same(event));
      expect(await second, same(event));
    });

    test('no repite los eventos publicados antes de suscribirse', () async {
      bus.publish(_EventA(1));
      await Future<void>.delayed(Duration.zero);
      final Future<List<_EventA>> received = bus.on<_EventA>().toList();

      bus.publish(_EventA(2));
      await bus.dispose();

      expect((await received).map((_EventA event) => event.value), <int>[2]);
    });

    test('publicar sin suscriptores no falla', () {
      expect(() => bus.publish(_EventA(1)), returnsNormally);
    });

    test('tras dispose, publicar no lanza y on termina sin emitir', () async {
      await bus.dispose();

      expect(() => bus.publish(_EventA(1)), returnsNormally);
      expect(await bus.on<_EventA>().toList(), isEmpty);
    });

    test('conserva emittedAt en UTC', () async {
      final DateTime at = DateTime.utc(2026, 10, 28, 9);
      final Future<_EventA> received = bus.on<_EventA>().first;

      bus.publish(_EventA(1, emittedAt: at));

      expect((await received).emittedAt, at);
    });
  });
}
