import '../model/sync_conflict.dart';

/// Bandeja de conflictos de este dispositivo.
abstract interface class ConflictRepository {
  /// Guarda [conflict] y reemplaza el que tenga su id.
  Future<void> save(SyncConflict conflict);

  Future<SyncConflict?> get(String id);

  /// Conflictos sin resolver, ordenados por `detectedAt` y después por id.
  Future<List<SyncConflict>> openConflicts();

  /// Emite [openConflicts] al escuchar y cada vez que cambia.
  Stream<List<SyncConflict>> watchOpenConflicts();
}
