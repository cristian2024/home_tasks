import 'dart:async';

/// Las pulsaciones de `AppShortcutService.selections` con la regla del
/// contrato: si llega una sin nadie escuchando, se guarda la última y se
/// entrega una sola vez, al primer oyente. Para las implementaciones.
class ShortcutSelectionBuffer {
  ShortcutSelectionBuffer() {
    _controller = StreamController<String>.broadcast(onListen: _flush);
  }

  late final StreamController<String> _controller;
  String? _pending;

  Stream<String> get stream => _controller.stream;

  /// Una pulsación del acceso [id].
  void add(String id) {
    if (_controller.hasListener) {
      _controller.add(id);
    } else {
      _pending = id;
    }
  }

  Future<void> close() => _controller.close();

  void _flush() {
    final String? pending = _pending;
    if (pending != null) {
      _pending = null;
      _controller.add(pending);
    }
  }
}
