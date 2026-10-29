import 'dart:async';

import 'cross_plugin_event.dart';
import 'event_bus.dart';

/// Suscripciones de un plugin al [EventBus]. El plugin la registra en su
/// scope con `dispose: (EventSubscriptions s) => s.cancelAll()`, así que al
/// descartar el scope (en su `dispose()`) se cancelan todas.
class EventSubscriptions {
  final List<StreamSubscription<Object?>> _subscriptions = <StreamSubscription<Object?>>[];
  bool _cancelled = false;

  /// Si ya se llamó a [cancelAll]: lo que se añada después se cancela al
  /// momento.
  bool get isCancelled => _cancelled;

  /// Escucha los eventos [T] de [bus] hasta [cancelAll].
  void listen<T extends CrossPluginEvent>(EventBus bus, void Function(T event) onEvent) =>
      add(bus.on<T>().listen(onEvent));

  void add(StreamSubscription<Object?> subscription) {
    if (_cancelled) {
      unawaited(subscription.cancel());
      return;
    }
    _subscriptions.add(subscription);
  }

  /// Cancela todas las suscripciones sin esperar a que terminen: esperar esos
  /// futuros puede bloquear con el reloj simulado de `testWidgets`.
  void cancelAll() {
    _cancelled = true;
    for (final StreamSubscription<Object?> subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }
}
