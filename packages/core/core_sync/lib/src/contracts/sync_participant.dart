import '../model/change_record.dart';
import '../model/sync_conflict.dart';

/// Una funcionalidad que se sincroniza (p. ej. item_tracker). Aplica los
/// cambios recibidos a sus datos con sus propias reglas.
abstract interface class SyncParticipant {
  /// Colecciones de las que se encarga.
  Set<String> get collections;

  /// Aplica [records] (todos de [collections]) de forma atómica, idempotente
  /// y conmutativa: los mismos registros, en cualquier orden, por lotes y con
  /// repeticiones, dan el mismo estado. No registra cambios nuevos, salvo las
  /// resoluciones provisionales de conflictos.
  ///
  /// Devuelve los conflictos detectados, ya con su resolución provisional
  /// aplicada.
  Future<List<SyncConflict>> applyRemote(List<ChangeRecord> records);

  /// Aplica la opción [optionId] de [conflict], elegida por el usuario. Lo
  /// hace con cambios locales, que se sincronizan.
  Future<void> resolveConflict(SyncConflict conflict, String optionId);
}
