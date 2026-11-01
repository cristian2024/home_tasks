import 'package:core_spaces/core_spaces.dart';
import 'package:core_utils/core_utils.dart';

import 'space_defaults.dart';

/// El espacio activo. Si no hay ninguno (el primer arranque, también al
/// venir de una versión con un solo espacio), crea uno con [defaultName] que
/// conserva la base de siempre ([SpaceDefaults.legacyDatabaseName]): los
/// datos, el log de la sincronización y las preferencias de los plugins se
/// siguen leyendo sin copiar nada. Su hogar lo anota después
/// `SpaceHouseholdTracker`, al abrir la base.
///
/// Si el proceso muere antes de guardar el espacio, el siguiente arranque
/// repite lo mismo.
Future<DataSpace> ensureActiveSpace({
  required DataSpaceDirectory directory,
  required String defaultName,
  IdGenerator ids = const UuidV4Generator(),
  Clock clock = const SystemClock(),
}) async {
  final DataSpace? active = await directory.active();
  if (active != null) {
    return active;
  }
  final DataSpace first = DataSpace(
    id: ids.newId(),
    name: defaultName,
    databaseName: SpaceDefaults.legacyDatabaseName,
    createdAt: clock.nowUtc(),
  );
  await directory.save(first);
  return first;
}
