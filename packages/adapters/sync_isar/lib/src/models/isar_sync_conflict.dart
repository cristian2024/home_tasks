import 'package:storage_isar/adapter.dart';

part 'isar_sync_conflict.g.dart';

/// Un conflicto de la bandeja.
@collection
class IsarSyncConflict {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String conflictId;

  late String collection;
  late String kind;
  late List<String> entityIds;

  /// Opciones con sus detalles, en JSON.
  late String options;

  late String provisionalOptionId;

  @Index()
  late DateTime detectedAt;

  String? resolvedOptionId;
}
