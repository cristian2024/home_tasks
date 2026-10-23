import '../entities/household_item.dart';

/// Vista jerárquica de un conjunto de objetos a partir de sus `parentId`.
///
/// Es tolerante a datos inconsistentes: un `parentId` que no existe se trata
/// como si el objeto no tuviera contenedor, y un ciclo se corta en cuanto se
/// detecta (los casos de uso impiden crearlos).
class ItemTree {
  ItemTree(Iterable<HouseholdItem> items) : _items = {for (final item in items) item.id: item} {
    for (final item in _items.values) {
      final parentId = item.parentId;
      if (parentId != null && _items.containsKey(parentId)) {
        (_children[parentId] ??= []).add(item);
      }
    }
    for (final children in _children.values) {
      children.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
  }

  final Map<String, HouseholdItem> _items;
  final Map<String, List<HouseholdItem>> _children = {};

  HouseholdItem? operator [](String id) => _items[id];

  /// Contenido directo de [id], ordenado por nombre.
  List<HouseholdItem> childrenOf(String id) => List.unmodifiable(_children[id] ?? const <HouseholdItem>[]);

  /// Contenedores de [id], del más externo al más interno (sin incluirlo).
  List<HouseholdItem> pathOf(String id) {
    final path = <HouseholdItem>[];
    final visited = {id};
    var parentId = _items[id]?.parentId;
    while (parentId != null && visited.add(parentId)) {
      final parent = _items[parentId];
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
  int heightOf(String id) => _height(id, {});

  int _height(String id, Set<String> visited) {
    if (!visited.add(id)) {
      return 0;
    }
    var tallest = 0;
    for (final child in _children[id] ?? const <HouseholdItem>[]) {
      final height = _height(child.id, visited);
      if (height > tallest) {
        tallest = height;
      }
    }
    return tallest + 1;
  }

  /// Si [id] está dentro de [ancestorId], directa o indirectamente.
  bool isInside(String id, {required String ancestorId}) => pathOf(id).any((item) => item.id == ancestorId);
}
