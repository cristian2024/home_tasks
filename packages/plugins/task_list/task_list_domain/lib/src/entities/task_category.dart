import 'package:categories/categories.dart';

/// Categorías que la lista crea la primera vez. Su nombre lo traduce la
/// presentación por [key] hasta que el usuario lo cambia.
enum DefaultTaskCategory {
  cleaning,
  kitchen,
  garden,
  bills,
  repairs;

  String get key => name;
}

/// Categoría de la lista de tareas: la común de `categories`.
typedef TaskCategory = ListCategory;
