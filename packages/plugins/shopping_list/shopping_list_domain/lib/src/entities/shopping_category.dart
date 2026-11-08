import 'package:categories/categories.dart';

/// Categorías que la lista crea la primera vez. Su nombre lo traduce la
/// presentación por [key] hasta que el usuario lo cambia.
enum DefaultShoppingCategory {
  food,
  hygiene,
  cleaning,
  home,
  pharmacy;

  String get key => name;
}

/// Categoría de la lista de compras: la común de `categories`.
typedef ShoppingCategory = ListCategory;
