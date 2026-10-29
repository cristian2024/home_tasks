import 'package:equatable/equatable.dart';
import 'package:urgency/urgency.dart';

import '../entities/shopping_category.dart';
import '../entities/shopping_item.dart';

/// Un item con su estado en un momento dado y sus categorías, ordenadas por
/// el orden de las categorías.
class ShoppingListEntry extends Equatable {
  const ShoppingListEntry({required this.item, required this.state, this.categories = const <ShoppingCategory>[]});

  final ShoppingItem item;
  final ShoppingItemState state;
  final List<ShoppingCategory> categories;

  /// La categoría bajo la que se agrupa; `null` si no tiene ninguna.
  ShoppingCategory? get primaryCategory => categories.isEmpty ? null : categories.first;

  @override
  List<Object?> get props => <Object?>[item, state, categories];
}

/// Qué items se muestran. Un criterio vacío no filtra.
class ShoppingListFilter extends Equatable {
  const ShoppingListFilter({
    this.categoryIds = const <String>{},
    this.includeUncategorized = false,
    this.urgencies = const <Urgency>{},
    this.states = const <ShoppingItemState>{},
  });

  /// Items con alguna de estas categorías.
  final Set<String> categoryIds;

  /// Incluye también los items sin categoría. Solo filtra por categoría si
  /// hay [categoryIds] o esto es `true`.
  final bool includeUncategorized;

  final Set<Urgency> urgencies;
  final Set<ShoppingItemState> states;

  bool get filtersByCategory => categoryIds.isNotEmpty || includeUncategorized;

  bool get isEmpty => !filtersByCategory && urgencies.isEmpty && states.isEmpty;

  bool matches(ShoppingListEntry entry) {
    if (filtersByCategory &&
        !entry.categories.any((ShoppingCategory category) => categoryIds.contains(category.id)) &&
        !(includeUncategorized && entry.categories.isEmpty)) {
      return false;
    }
    if (urgencies.isNotEmpty && !urgencies.contains(entry.item.urgency)) {
      return false;
    }
    return states.isEmpty || states.contains(entry.state);
  }

  ShoppingListFilter copyWith({
    Set<String>? categoryIds,
    bool? includeUncategorized,
    Set<Urgency>? urgencies,
    Set<ShoppingItemState>? states,
  }) =>
      ShoppingListFilter(
        categoryIds: categoryIds ?? this.categoryIds,
        includeUncategorized: includeUncategorized ?? this.includeUncategorized,
        urgencies: urgencies ?? this.urgencies,
        states: states ?? this.states,
      );

  @override
  List<Object?> get props => <Object?>[categoryIds, includeUncategorized, urgencies, states];
}

/// Cómo se agrupan los items en la lista y al exportar.
enum ShoppingGrouping { category, urgency }

/// Grupo de la lista. Agrupando por categoría tiene [category] (`null` para
/// «Sin categoría»); agrupando por urgencia, [urgency].
class ShoppingGroup extends Equatable {
  const ShoppingGroup.category(this.category, this.entries) : urgency = null;

  const ShoppingGroup.urgency(Urgency this.urgency, this.entries) : category = null;

  final ShoppingCategory? category;
  final Urgency? urgency;
  final List<ShoppingListEntry> entries;

  @override
  List<Object?> get props => <Object?>[category, urgency, entries];
}

/// Reglas puras para mostrar y exportar la lista.
abstract final class ShoppingListView {
  /// Une cada item con su estado en [now] y sus categorías (por su orden; los
  /// IDs que no existen se ignoran).
  static List<ShoppingListEntry> entries(
    List<ShoppingItem> items,
    List<ShoppingCategory> categories,
    DateTime now,
  ) {
    final List<ShoppingCategory> ordered = sortCategories(categories);
    return <ShoppingListEntry>[
      for (final ShoppingItem item in items)
        ShoppingListEntry(
          item: item,
          state: item.stateAt(now),
          categories: <ShoppingCategory>[
            for (final ShoppingCategory category in ordered)
              if (item.categoryIds.contains(category.id)) category,
          ],
        ),
    ];
  }

  /// Categorías por [ShoppingCategory.sortOrder]; a igual orden, por ID.
  static List<ShoppingCategory> sortCategories(List<ShoppingCategory> categories) =>
      categories.toList()
        ..sort((ShoppingCategory a, ShoppingCategory b) {
          final int bySortOrder = a.sortOrder.compareTo(b.sortOrder);
          return bySortOrder != 0 ? bySortOrder : a.id.compareTo(b.id);
        });

  /// Orden dentro de un grupo: primero lo atrasado y lo pendiente, luego lo
  /// que espera y al final lo comprado; a igual estado, lo más urgente, y
  /// después por nombre.
  static int compare(ShoppingListEntry a, ShoppingListEntry b) {
    final int byState = a.state.index.compareTo(b.state.index);
    if (byState != 0) {
      return byState;
    }
    final int byUrgency = a.item.urgency.compareTo(b.item.urgency);
    return byUrgency != 0 ? byUrgency : a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
  }

  /// Agrupa [entries] (ya filtradas). Por categoría, cada item sale una sola
  /// vez, bajo su primera categoría; los grupos siguen el orden de las
  /// categorías y «Sin categoría» va al final. Por urgencia, de más a menos
  /// urgente. Solo hay grupos con items, ordenados con [compare].
  static List<ShoppingGroup> group(List<ShoppingListEntry> entries, ShoppingGrouping grouping) {
    switch (grouping) {
      case ShoppingGrouping.urgency:
        return <ShoppingGroup>[
          for (final Urgency urgency in Urgency.values)
            if (_sorted(entries.where((ShoppingListEntry entry) => entry.item.urgency == urgency))
                case final List<ShoppingListEntry> group when group.isNotEmpty)
              ShoppingGroup.urgency(urgency, group),
        ];
      case ShoppingGrouping.category:
        final Map<String, ShoppingCategory> categories = <String, ShoppingCategory>{
          for (final ShoppingListEntry entry in entries)
            if (entry.primaryCategory case final ShoppingCategory category) category.id: category,
        };
        final List<ShoppingListEntry> uncategorized =
            _sorted(entries.where((ShoppingListEntry entry) => entry.primaryCategory == null));
        return <ShoppingGroup>[
          for (final ShoppingCategory category in sortCategories(categories.values.toList()))
            ShoppingGroup.category(
              category,
              _sorted(entries.where((ShoppingListEntry entry) => entry.primaryCategory?.id == category.id)),
            ),
          if (uncategorized.isNotEmpty) ShoppingGroup.category(null, uncategorized),
        ];
    }
  }

  static List<ShoppingListEntry> _sorted(Iterable<ShoppingListEntry> entries) => entries.toList()..sort(compare);
}
