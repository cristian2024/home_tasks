import 'package:equatable/equatable.dart';

/// Una categoría de una lista. Las que la lista crea la primera vez tienen
/// [defaultKey] y se traducen por ella hasta que el usuario las renombra.
class ListCategory extends Equatable {
  /// [name] o [defaultKey] debe tener valor.
  const ListCategory({
    required this.id,
    required this.sortOrder,
    this.name,
    this.defaultKey,
  }) : assert(name != null || defaultKey != null, 'Una categoría necesita nombre o clave por defecto');

  final String id; // UUID v4, inmutable

  /// Nombre que puso el usuario; `null` en una categoría por defecto que no
  /// se ha renombrado.
  final String? name;

  /// Clave de la categoría por defecto de la que viene, si es una.
  final String? defaultKey;

  /// Posición en la lista de categorías (0 primero).
  final int sortOrder;

  ListCategory copyWith({String? name, int? sortOrder}) =>
      ListCategory(id: id, name: name ?? this.name, defaultKey: defaultKey, sortOrder: sortOrder ?? this.sortOrder);

  @override
  List<Object?> get props => <Object?>[id, name, defaultKey, sortOrder];

  @override
  bool get stringify => true;
}

/// Por qué no vale un nombre de categoría.
enum CategoryNameProblem { empty, tooLong }

/// Reglas comunes de las categorías.
abstract final class ListCategories {
  static const int maxNameLength = 40;

  static final RegExp _spaces = RegExp(r'\s+');

  /// Forma con que se comparan nombres: sin mayúsculas ni espacios de sobra.
  static String normalize(String value) => value.trim().replaceAll(_spaces, ' ').toLowerCase();

  /// Qué falla en [name], ya sin espacios al principio ni al final; `null` si
  /// vale.
  static CategoryNameProblem? problemWith(String name) => switch (name.length) {
        0 => CategoryNameProblem.empty,
        > maxNameLength => CategoryNameProblem.tooLong,
        _ => null,
      };

  /// Si otra categoría (distinta de [exceptId]) ya se llama [name], sin
  /// distinguir mayúsculas. [nameOf] da el nombre visible, que en las
  /// categorías por defecto depende del idioma.
  static bool isNameTaken(
    Iterable<ListCategory> categories,
    String name, {
    required String Function(ListCategory category) nameOf,
    String? exceptId,
  }) {
    final String key = normalize(name);
    return categories.any((ListCategory category) => category.id != exceptId && normalize(nameOf(category)) == key);
  }

  /// Por [ListCategory.sortOrder]; a igual orden, por ID.
  static List<ListCategory> sorted(Iterable<ListCategory> categories) => categories.toList()
    ..sort((ListCategory a, ListCategory b) {
      final int bySortOrder = a.sortOrder.compareTo(b.sortOrder);
      return bySortOrder != 0 ? bySortOrder : a.id.compareTo(b.id);
    });

  /// Posición para una categoría nueva, al final.
  static int nextSortOrder(Iterable<ListCategory> categories) =>
      categories.isEmpty ? 0 : sorted(categories).last.sortOrder + 1;

  /// [categories] con las posiciones de [orderedIds], que debe tener
  /// exactamente sus IDs. Si no, lanza [ArgumentError].
  static List<ListCategory> reordered(Iterable<ListCategory> categories, List<String> orderedIds) {
    final Map<String, ListCategory> byId = <String, ListCategory>{
      for (final ListCategory category in categories) category.id: category,
    };
    if (orderedIds.length != byId.length || !byId.keys.toSet().containsAll(orderedIds)) {
      throw ArgumentError.value(orderedIds, 'orderedIds', 'Debe contener exactamente los IDs de todas las categorías');
    }
    return <ListCategory>[
      for (int i = 0; i < orderedIds.length; i++) byId[orderedIds[i]]!.copyWith(sortOrder: i),
    ];
  }
}
