/// Espacios de datos: cada uno es un conjunto de datos con su propia base,
/// local o ligado a un hogar de sincronización. El dispositivo tiene uno o
/// varios y usa uno, el activo. Contratos en Dart puro; las implementaciones
/// las elige quien compone (p. ej. `spaces_shared_preferences` y
/// `storage_isar`).
library;

export 'src/data_space.dart';
export 'src/data_space_directory.dart';
export 'src/data_space_exception.dart';
export 'src/data_space_storage.dart';
export 'src/orphan_databases.dart';
