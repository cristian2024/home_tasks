import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:storage_isar/adapter.dart';

import 'models/isar_sync_change_record.dart';
import 'models/isar_sync_conflict.dart';
import 'models/isar_sync_peer.dart';
import 'models/isar_sync_state.dart';
import 'models/isar_sync_vector_entry.dart';
import 'repositories/isar_change_log.dart';
import 'repositories/isar_change_log_writer.dart';
import 'repositories/isar_conflict_repository.dart';
import 'repositories/isar_sync_state_repository.dart';

/// Adaptador Isar de la sincronización. Quien compone la app solo lo elige,
/// dentro de `IsarStorage(features: <IsarFeature>[..., SyncIsar()])`.
///
/// Con la base abierta registra `ChangeLog`, `SyncStateRepository` y
/// `ConflictRepository`, y el [IsarChangeLogWriter] para los adaptadores Isar
/// de las funcionalidades. La clave del hogar no se guarda aquí.
class SyncIsar implements IsarFeature {
  const SyncIsar();

  @override
  List<CollectionSchema<dynamic>> get schemas => const <CollectionSchema<dynamic>>[
        IsarSyncChangeRecordSchema,
        IsarSyncVectorEntrySchema,
        IsarSyncStateSchema,
        IsarSyncPeerSchema,
        IsarSyncConflictSchema,
      ];

  @override
  void register(ServiceLocator services, Isar isar) => services
    ..registerSingleton<ChangeLog>(IsarChangeLog(isar))
    ..registerSingleton<SyncStateRepository>(IsarSyncStateRepository(isar))
    ..registerSingleton<ConflictRepository>(IsarConflictRepository(isar))
    ..registerSingleton<IsarChangeLogWriter>(IsarChangeLogWriter(isar));
}
