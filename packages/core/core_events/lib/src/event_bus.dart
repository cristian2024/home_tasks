import 'package:rxdart/rxdart.dart';

import 'cross_plugin_event.dart';

class EventBus {
  final PublishSubject<CrossPluginEvent> _subject = PublishSubject<CrossPluginEvent>();

  /// Publica [event] a los suscriptores actuales. Tras [dispose] los eventos
  /// se descartan en silencio.
  void publish(CrossPluginEvent event) {
    if (!_subject.isClosed) {
      _subject.add(event);
    }
  }

  /// Emite los eventos de tipo [T] (incluidos subtipos) publicados a partir
  /// de la suscripción.
  Stream<T> on<T extends CrossPluginEvent>() => _subject.whereType<T>();

  Future<void> dispose() => _subject.close();
}
