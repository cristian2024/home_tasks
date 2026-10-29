/// Dobles de prueba y tests de contrato de `core_events`.
library;

import 'core_events.dart';

export 'src/testing/event_bus_contract.dart';

/// [EventBus] que además guarda todo lo publicado, para comprobar en un test
/// qué publicó un plugin. Cumple `eventBusContract`.
class RecordingEventBus implements EventBus {
  final StreamEventBus _bus = StreamEventBus();
  final List<CrossPluginEvent> _published = <CrossPluginEvent>[];

  /// Eventos publicados, en orden (también los descartados tras [dispose]).
  List<CrossPluginEvent> get published => List<CrossPluginEvent>.unmodifiable(_published);

  /// Eventos publicados de tipo [T].
  List<T> publishedOf<T extends CrossPluginEvent>() => _published.whereType<T>().toList();

  @override
  void publish(CrossPluginEvent event) {
    _published.add(event);
    _bus.publish(event);
  }

  @override
  Stream<T> on<T extends CrossPluginEvent>() => _bus.on<T>();

  @override
  Future<void> dispose() => _bus.dispose();
}
