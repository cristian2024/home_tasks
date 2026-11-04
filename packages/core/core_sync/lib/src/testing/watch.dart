import 'dart:async';

/// Stream que emite [read] al escuchar y cada vez que [changes] avisa.
Stream<T> watchValue<T>(Stream<void> changes, T Function() read) {
  late final StreamController<T> controller;
  StreamSubscription<void>? subscription;
  controller = StreamController<T>(
    onListen: () {
      controller.add(read());
      subscription = changes.listen((_) => controller.add(read()));
    },
    // No devuelve el futuro de cancel(): `first` lo esperaría y, con el reloj
    // simulado de testWidgets, no se completa.
    onCancel: () {
      unawaited(subscription?.cancel());
      unawaited(controller.close());
    },
  );
  return controller.stream;
}
