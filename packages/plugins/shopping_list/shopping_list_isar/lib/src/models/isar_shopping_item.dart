import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:storage_isar/adapter.dart';

part 'isar_shopping_item.g.dart';

@collection
class IsarShoppingItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID v4

  late String name;
  late String notes;
  late String quantity;

  @Enumerated(EnumType.name)
  late Urgency urgency;

  @Enumerated(EnumType.name)
  late ShoppingItemStatus status;

  /// Índice multiEntry: permite buscar los items de una categoría al borrarla.
  @Index(type: IndexType.value)
  List<String> categoryIds = <String>[];

  /// Recurrencia: los dos `null` si no se repite.
  int? recurrenceMinDays;
  int? recurrenceMaxDays;

  DateTime? lastPurchasedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
}
