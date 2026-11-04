/// Adaptador Isar de la sincronización.
///
/// Quien compone la app solo elige [SyncIsar], dentro de `IsarStorage`. Los
/// adaptadores Isar de las funcionalidades usan [IsarChangeLogWriter] para
/// escribir el registro de cambio en la misma transacción que la entidad.
library;

export 'src/repositories/isar_change_log_writer.dart';
export 'src/sync_isar.dart';
