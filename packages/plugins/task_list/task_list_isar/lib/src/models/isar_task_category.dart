import 'package:storage_isar/adapter.dart';

part 'isar_task_category.g.dart';

@collection
class IsarTaskCategory {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID v4

  String? name;
  String? defaultKey;

  @Index()
  late int sortOrder;

  /// Borrado lógico: `null` si está activa.
  DateTime? deletedAt;
}
