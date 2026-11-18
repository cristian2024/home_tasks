import 'package:categories/categories.dart';
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
///
/// La lista empieza con [defaults]: solo lo que hay que comprar ahora.
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

  /// El filtro con el que empieza la lista: pendiente y atrasado. «En espera»
  /// y «Comprado» solo se ven al elegirlos.
  static const ShoppingListFilter defaults = ShoppingListFilter(
    states: <ShoppingItemState>{ShoppingItemState.pending, ShoppingItemState.overdue},
  );

  final Set<Urgency> urgencies;
  final Set<ShoppingItemState> states;

  /// Si es [defaults] (p. ej. para desactivar «Restablecer»).
  bool get isDefault => this == defaults;

  /// La única categoría por la que filtra; `null` si filtra por ninguna, por
  /// varias o también por «Sin categoría».
  String? get singleCategoryId => categoryIds.length == 1 && !includeUncategorized ? categoryIds.first : null;

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
  static List<ShoppingCategory> sortCategories(List<ShoppingCategory> categories) => ListCategories.sorted(categories);

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

  /// Lo comprado (items normales; los recurrentes nunca lo están), de lo más
  /// reciente a lo más antiguo.
  static List<ShoppingListEntry> bought(List<ShoppingListEntry> entries) =>
      entries.where((ShoppingListEntry entry) => entry.state == ShoppingItemState.purchased).toList()
        ..sort((ShoppingListEntry a, ShoppingListEntry b) {
          final int byDate = _compareDates(a.item.lastPurchasedAt, b.item.lastPurchasedAt, newestFirst: true);
          return byDate != 0 ? byDate : compare(a, b);
        });

  /// Lo que espera a su siguiente ventana, de lo que vuelve antes a lo que
  /// vuelve después.
  static List<ShoppingListEntry> waiting(List<ShoppingListEntry> entries) =>
      entries.where((ShoppingListEntry entry) => entry.state == ShoppingItemState.waiting).toList()
        ..sort((ShoppingListEntry a, ShoppingListEntry b) {
          final int byDate = _compareDates(a.item.returnsAt, b.item.returnsAt);
          return byDate != 0 ? byDate : compare(a, b);
        });

  /// La categoría de un item creado desde la lista: la del filtro si filtra
  /// por una sola; si no, [lastUsedId], la última usada al crear; `null` (sin
  /// categoría) si no hay o ya no existe.
  static String? quickAddCategory({
    required ShoppingListFilter filter,
    required String? lastUsedId,
    required List<ShoppingCategory> categories,
  }) {
    final String? candidate = filter.singleCategoryId ?? lastUsedId;
    return categories.any((ShoppingCategory category) => category.id == candidate) ? candidate : null;
  }

  /// Ordena las fechas, de la más antigua a la más reciente o, con
  /// [newestFirst], al revés. `null` siempre va al final.
  static int _compareDates(DateTime? a, DateTime? b, {bool newestFirst = false}) => switch ((a, b)) {
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
        (final DateTime a, final DateTime b) => newestFirst ? b.compareTo(a) : a.compareTo(b),
      };

  static List<ShoppingListEntry> _sorted(Iterable<ShoppingListEntry> entries) => entries.toList()..sort(compare);
}
