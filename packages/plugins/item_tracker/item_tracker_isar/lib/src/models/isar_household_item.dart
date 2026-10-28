import 'package:storage_isar/adapter.dart';

part 'isar_household_item.g.dart';

@collection
class IsarHouseholdItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID v4

  @Index(caseSensitive: false)
  late String name;

  late String description;
  late String metadataJson; // Serialización JSON de ItemMetadata.values

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  /// `HouseholdItem.parentId`. Los registros anteriores a este campo se leen
  /// como `null` (sin contenedor).
  @Index()
  String? parentId;
}
