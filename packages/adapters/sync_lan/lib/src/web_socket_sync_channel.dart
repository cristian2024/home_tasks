import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_sync/core_sync.dart';

/// [SyncChannel] sobre un [WebSocket]: cada mensaje es una trama binaria.
class WebSocketSyncChannel implements SyncChannel {
  WebSocketSyncChannel(this._socket) {
    _socket.listen(
      (Object? data) {
        if (data is List<int>) {
          _messages.add(Uint8List.fromList(data));
        }
      },
      onError: (Object _) => _finish(),
      onDone: _finish,
      cancelOnError: true,
    );
  }

  final WebSocket _socket;
  final StreamController<Uint8List> _messages = StreamController<Uint8List>();
  bool _closed = false;

  @override
  Stream<Uint8List> get messages => _messages.stream;

  @override
  Future<void> send(Uint8List message) async {
    if (_closed) {
      throw const SyncTransportException('Canal cerrado');
    }
    _socket.add(message);
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _finish();
    // No se espera: se completa cuando el otro lado confirma el cierre.
    unawaited(_socket.close(WebSocketStatus.normalClosure));
  }

  void _finish() {
    _closed = true;
    // No se espera: el futuro solo se completa cuando alguien escucha.
    unawaited(_messages.close());
  }
}
