import 'dart:async';

import 'cross_plugin_event.dart';

/// Canal de eventos entre plugins: quien publica no sabe quién escucha.
///
/// La app registra una instancia en el scope raíz del `ServiceLocator`. Los
/// eventos no se guardan: un suscriptor solo recibe los publicados después de
/// suscribirse.
abstract interface class EventBus {
  /// Implementación por defecto, en memoria.
  factory EventBus() = StreamEventBus;

  /// Publica [event] a los suscriptores actuales. Tras [dispose] los eventos
  /// se descartan en silencio.
  void publish(CrossPluginEvent event);

  /// Emite los eventos de tipo [T] (incluidos subtipos) publicados a partir
  /// de la suscripción. Tras [dispose] termina sin emitir.
  Stream<T> on<T extends CrossPluginEvent>();

  Future<void> dispose();
}

/// [EventBus] en memoria sobre un `StreamController` broadcast. Entrega los
/// eventos de forma asíncrona, en el orden en que se publicaron.
class StreamEventBus implements EventBus {
  final StreamController<CrossPluginEvent> _controller = StreamController<CrossPluginEvent>.broadcast();

  @override
  void publish(CrossPluginEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  @override
  Stream<T> on<T extends CrossPluginEvent>() =>
      _controller.stream.where((CrossPluginEvent event) => event is T).cast<T>();

  @override
  Future<void> dispose() => _controller.close();
}
