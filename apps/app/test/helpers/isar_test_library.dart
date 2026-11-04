import 'dart:io';

import 'package:storage_isar/adapter.dart' show Isar;

/// Sin sobrescribir nada, `HttpOverrides` crea el cliente real de `dart:io`.
class _RealHttpClient extends HttpOverrides {}

/// Prepara `libisar` para los tests que usan Isar de verdad, desde `setUpAll`.
///
/// `testWidgets` crea el binding de tests al declarar el test, antes de
/// `setUpAll`, y ese binding responde 400 a toda petición HTTP. Por eso la
/// descarga usa un cliente real. El bloqueo es porque cada archivo de test es un
/// proceso: sin él, uno podría cargar la librería mientras otro aún la escribe.
Future<void> initializeIsarForTests() async {
  final RandomAccessFile lock = await File('${Directory.systemTemp.path}/home_tasks_libisar.lock').open(mode: FileMode.write);
  await lock.lock(FileLock.blockingExclusive);
  try {
    await HttpOverrides.runWithHttpOverrides(() => Isar.initializeIsarCore(download: true), _RealHttpClient());
  } finally {
    await lock.unlock();
    await lock.close();
  }
}
