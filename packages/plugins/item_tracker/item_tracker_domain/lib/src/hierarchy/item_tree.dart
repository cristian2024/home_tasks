import '../entities/household_item.dart';

/// Vista jerárquica de un conjunto de objetos a partir de sus `parentId`.
///
/// Es tolerante a datos inconsistentes: un `parentId` que no existe se trata
/// como si el objeto no tuviera contenedor, y un ciclo se corta en cuanto se
/// detecta (los casos de uso impiden crearlos).
class ItemTree {
  ItemTree(Iterable<HouseholdItem> items)
      : _items = <String, HouseholdItem>{for (final HouseholdItem item in items) item.id: item} {
    for (final HouseholdItem item in _items.values) {
      final String? parentId = item.parentId;
      if (parentId != null && _items.containsKey(parentId)) {
        (_children[parentId] ??= <HouseholdItem>[]).add(item);
      }
    }
    for (final List<HouseholdItem> children in _children.values) {
      children.sort((HouseholdItem a, HouseholdItem b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
  }

  final Map<String, HouseholdItem> _items;
  final Map<String, List<HouseholdItem>> _children = <String, List<HouseholdItem>>{};

  HouseholdItem? operator [](String id) => _items[id];

  /// Todos los objetos, en el orden en que se recibieron.
  List<HouseholdItem> get items => List<HouseholdItem>.unmodifiable(_items.values);

  /// Contenido directo de [id], ordenado por nombre.
  List<HouseholdItem> childrenOf(String id) =>
      List<HouseholdItem>.unmodifiable(_children[id] ?? const <HouseholdItem>[]);

  /// Todo lo que contiene [id] a cualquier profundidad (sin incluirlo), con
  /// cada contenedor antes que su contenido.
  List<HouseholdItem> descendantsOf(String id) {
    final List<HouseholdItem> descendants = <HouseholdItem>[];
    final Set<String> visited = <String>{id};
    void collect(String parentId) {
      for (final HouseholdItem child in _children[parentId] ?? const <HouseholdItem>[]) {
        if (visited.add(child.id)) {
          descendants.add(child);
          collect(child.id);
        }
      }
    }

    collect(id);
    return descendants;
  }

  /// Contenedores de [id], del más externo al más interno (sin incluirlo).
  List<HouseholdItem> pathOf(String id) {
    final List<HouseholdItem> path = <HouseholdItem>[];
    final Set<String> visited = <String>{id};
    String? parentId = _items[id]?.parentId;
    while (parentId != null && visited.add(parentId)) {
      final HouseholdItem? parent = _items[parentId];
      if (parent == null) {
        break;
      }
      path.add(parent);
      parentId = parent.parentId;
    }
    return path.reversed.toList();
  }

  /// Nivel de [id]: 1 si no está dentro de nada.
  int depthOf(String id) => pathOf(id).length + 1;

  /// Niveles que ocupa [id] con todo su contenido: 1 si no contiene nada.
  int heightOf(String id) => _height(id, <String>{});

  int _height(String id, Set<String> visited) {
    if (!visited.add(id)) {
      return 0;
    }
    int tallest = 0;
    for (final HouseholdItem child in _children[id] ?? const <HouseholdItem>[]) {
      final int height = _height(child.id, visited);
      if (height > tallest) {
        tallest = height;
      }
    }
    return tallest + 1;
  }

  /// Si [id] está dentro de [ancestorId], directa o indirectamente.
  bool isInside(String id, {required String ancestorId}) =>
      pathOf(id).any((HouseholdItem item) => item.id == ancestorId);
}
