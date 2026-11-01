import 'dart:developer' as developer;

import 'package:core_spaces/core_spaces.dart';
import 'package:core_utils/core_utils.dart';

import '../bootstrap.dart';
import 'active_space.dart';
import 'device_environment.dart';
import 'space_switcher.dart';

/// Arranque con espacios de datos: el espacio activo (en el primer arranque,
/// la base de siempre, sin copiar nada), la limpieza de las bases de espacios
/// borrados a medias y el entorno del activo.
Future<SpaceSwitcher> bootstrapSpaces({
  required DeviceEnvironment device,
  required SpaceOpener open,
  required String defaultName,
  required String Function(int number) newSpaceName,
  IdGenerator ids = const UuidV4Generator(),
  Clock clock = const SystemClock(),
}) async {
  final DataSpace space =
      await ensureActiveSpace(directory: device.spaces, defaultName: defaultName, ids: ids, clock: clock);
  try {
    await deleteOrphanDatabases(directory: device.spaces, storage: device.spaceStorage);
  } on Object catch (error, stackTrace) {
    // No impide arrancar: se intentará en el próximo arranque.
    developer.log('No se pudieron borrar las bases huérfanas', name: 'home_utility_app', error: error, stackTrace: stackTrace);
  }
  final AppEnvironment environment = await open(space);
  return SpaceSwitcher(
    device: device,
    initial: environment,
    open: open,
    newSpaceName: newSpaceName,
    ids: ids,
    clock: clock,
  );
}
