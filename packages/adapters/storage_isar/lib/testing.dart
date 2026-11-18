/// Ayudas para los tests que usan Isar de verdad.
library;

import 'dart:io';

import 'package:isar_community/isar.dart';

/// Sin sobrescribir nada, `HttpOverrides` crea el cliente real de `dart:io`.
class _RealHttpClient extends HttpOverrides {}

/// Prepara `libisar` para los tests que usan Isar de verdad. Se llama desde
/// `setUpAll`: `setUpAll(initializeIsarForTests);`.
///
/// Isar intenta abrir la librería y, si no puede, la descarga en la carpeta
/// del paquete, sobrescribiendo el archivo. Cada archivo de test es un proceso,
/// así que sin el bloqueo uno puede cargarla mientras otro la escribe: falla
/// con «file too short» o el proceso cae con SIGBUS (exit -7). Con el bloqueo,
/// el segundo espera y la encuentra completa.
///
/// La descarga usa un cliente HTTP real porque `testWidgets` crea el binding
/// de tests al declarar el test, antes de `setUpAll`, y ese binding responde
/// 400 a toda petición.
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
