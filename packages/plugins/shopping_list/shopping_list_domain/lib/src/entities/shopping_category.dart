import 'package:equatable/equatable.dart';

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

class ShoppingCategory extends Equatable {
  /// [name] o [defaultKey] debe tener valor.
  const ShoppingCategory({
    required this.id,
    required this.sortOrder,
    this.name,
    this.defaultKey,
  }) : assert(name != null || defaultKey != null, 'Una categoría necesita nombre o clave por defecto');

  final String id; // UUID v4, inmutable

  /// Nombre que puso el usuario; `null` en una categoría por defecto que no
  /// se ha renombrado.
  final String? name;

  /// Clave de [DefaultShoppingCategory] si es una categoría por defecto.
  final String? defaultKey;

  /// Posición en la lista de categorías (0 primero).
  final int sortOrder;

  ShoppingCategory copyWith({String? name, int? sortOrder}) =>
      ShoppingCategory(id: id, name: name ?? this.name, defaultKey: defaultKey, sortOrder: sortOrder ?? this.sortOrder);

  @override
  List<Object?> get props => <Object?>[id, name, defaultKey, sortOrder];

  @override
  bool get stringify => true;
}
