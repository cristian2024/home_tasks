import 'package:storage_isar/adapter.dart';

part 'isar_shopping_list_flag.g.dart';

/// Marcas de la lista que se guardan una vez (p. ej. si ya se crearon las
/// categorías por defecto). Su existencia es la marca.
@collection
class IsarShoppingListFlag {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;
}
