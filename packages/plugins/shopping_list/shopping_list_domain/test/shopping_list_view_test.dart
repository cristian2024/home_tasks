import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:test/test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 10, 28, 12);
  const ShoppingCategory food = ShoppingCategory(id: 'food', sortOrder: 0, defaultKey: 'food');
  const ShoppingCategory cleaning = ShoppingCategory(id: 'cleaning', sortOrder: 1, defaultKey: 'cleaning');
  const ShoppingCategory home = ShoppingCategory(id: 'home', sortOrder: 2, name: 'Hogar');
  const List<ShoppingCategory> categories = <ShoppingCategory>[home, food, cleaning];

  ShoppingItem item(
    String name, {
    List<String> categoryIds = const <String>[],
    Urgency urgency = Urgency.normal,
    ShoppingItemStatus status = ShoppingItemStatus.pending,
    Recurrence? recurrence,
    DateTime? lastPurchasedAt,
  }) =>
      ShoppingItem(
        id: name,
        name: name,
        urgency: urgency,
        status: status,
        categoryIds: categoryIds,
        recurrence: recurrence,
        lastPurchasedAt: lastPurchasedAt,
        createdAt: now,
        updatedAt: now,
      );

  List<String> names(List<ShoppingListEntry> entries) =>
      <String>[for (final ShoppingListEntry entry in entries) entry.item.name];

  group('entries', () {
    test('une cada item con su estado y sus categorías por orden, ignorando las que no existen', () {
      final List<ShoppingListEntry> entries = ShoppingListView.entries(
        <ShoppingItem>[item('Lejía', categoryIds: <String>['home', 'missing', 'cleaning'])],
        categories,
        now,
      );

      expect(entries.single.state, ShoppingItemState.pending);
      expect(entries.single.categories, <ShoppingCategory>[cleaning, home]);
      expect(entries.single.primaryCategory, cleaning);
    });

    test('un item sin categorías no tiene categoría principal', () {
      expect(ShoppingListView.entries(<ShoppingItem>[item('Pilas')], categories, now).single.primaryCategory, isNull);
    });
  });

  test('ShoppingListEntry y ShoppingGroup: igualdad por valor', () {
    ShoppingListEntry entry(String name) =>
        ShoppingListView.entries(<ShoppingItem>[item(name)], categories, now).single;

    expect(entry('Pan'), entry('Pan'));
    expect(entry('Pan'), isNot(entry('Sal')));
    expect(ShoppingGroup.category(food, <ShoppingListEntry>[entry('Pan')]),
        ShoppingGroup.category(food, <ShoppingListEntry>[entry('Pan')]));
    expect(const ShoppingGroup.urgency(Urgency.low, <ShoppingListEntry>[]),
        isNot(const ShoppingGroup.urgency(Urgency.high, <ShoppingListEntry>[])));
  });

  test('sortCategories ordena por sortOrder y desempata por ID', () {
    const ShoppingCategory b = ShoppingCategory(id: 'b', sortOrder: 0, name: 'B');
    const ShoppingCategory a = ShoppingCategory(id: 'a', sortOrder: 0, name: 'A');

    expect(ShoppingListView.sortCategories(<ShoppingCategory>[home, b, a]), <ShoppingCategory>[a, b, home]);
  });

  group('ShoppingListFilter', () {
    final List<ShoppingListEntry> entries = ShoppingListView.entries(
      <ShoppingItem>[
        item('Huevos', categoryIds: <String>['food'], urgency: Urgency.high),
        item('Lejía', categoryIds: <String>['cleaning', 'home']),
        item('Pilas'),
        item('Pan', categoryIds: <String>['food'], status: ShoppingItemStatus.purchased),
      ],
      categories,
      now,
    );

    List<String> filtered(ShoppingListFilter filter) => names(entries.where(filter.matches).toList());

    test('sin criterios no filtra', () {
      const ShoppingListFilter filter = ShoppingListFilter();

      expect(filter.isEmpty, isTrue);
      expect(filtered(filter), <String>['Huevos', 'Lejía', 'Pilas', 'Pan']);
    });

    test('por categorías: cualquiera de las elegidas, y opcionalmente las que no tienen', () {
      expect(
        filtered(const ShoppingListFilter(categoryIds: <String>{'home', 'food'})),
        <String>['Huevos', 'Lejía', 'Pan'],
      );
      expect(filtered(const ShoppingListFilter(includeUncategorized: true)), <String>['Pilas']);
      expect(
        filtered(const ShoppingListFilter(categoryIds: <String>{'cleaning'}, includeUncategorized: true)),
        <String>['Lejía', 'Pilas'],
      );
    });

    test('por urgencia y por estado', () {
      expect(filtered(const ShoppingListFilter(urgencies: <Urgency>{Urgency.high})), <String>['Huevos']);
      expect(
        filtered(const ShoppingListFilter(states: <ShoppingItemState>{ShoppingItemState.purchased})),
        <String>['Pan'],
      );
    });

    test('combina los criterios', () {
      const ShoppingListFilter filter = ShoppingListFilter(
        categoryIds: <String>{'food'},
        states: <ShoppingItemState>{ShoppingItemState.pending},
      );

      expect(filter.isEmpty, isFalse);
      expect(filtered(filter), <String>['Huevos']);
    });

    test('copyWith cambia solo lo indicado', () {
      const ShoppingListFilter filter = ShoppingListFilter(categoryIds: <String>{'food'});

      expect(
        filter.copyWith(
          includeUncategorized: true,
          urgencies: <Urgency>{Urgency.low},
          states: <ShoppingItemState>{ShoppingItemState.waiting},
        ),
        const ShoppingListFilter(
          categoryIds: <String>{'food'},
          includeUncategorized: true,
          urgencies: <Urgency>{Urgency.low},
          states: <ShoppingItemState>{ShoppingItemState.waiting},
        ),
      );
      expect(filter.copyWith(categoryIds: <String>{}), const ShoppingListFilter());
    });
  });

  group('group', () {
    final DateTime longAgo = now.subtract(const Duration(days: 30));
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    final List<ShoppingListEntry> entries = ShoppingListView.entries(
      <ShoppingItem>[
        item('pan', categoryIds: <String>['food']),
        item('Arroz', categoryIds: <String>['food']),
        item('Huevos', categoryIds: <String>['food'], recurrence: Recurrence.between(8, 15), lastPurchasedAt: longAgo),
        item('Leche', categoryIds: <String>['food'], recurrence: Recurrence.fixed(7), lastPurchasedAt: yesterday),
        item('Queso', categoryIds: <String>['food'], status: ShoppingItemStatus.purchased, urgency: Urgency.immediate),
        item('Jabón', categoryIds: <String>['food', 'cleaning'], urgency: Urgency.immediate),
        item('Lejía', categoryIds: <String>['home', 'cleaning'], urgency: Urgency.high),
        item('Pilas', urgency: Urgency.low),
      ],
      categories,
      now,
    );

    test('compare: atrasado, pendiente, en espera y comprado; luego urgencia y nombre', () {
      final List<ShoppingListEntry> food =
          ShoppingListView.group(entries, ShoppingGrouping.category).first.entries;

      expect(names(food), <String>['Huevos', 'Jabón', 'Arroz', 'pan', 'Leche', 'Queso']);
    });

    test('por categoría: cada item una vez, bajo su primera categoría; «Sin categoría» al final', () {
      final List<ShoppingGroup> groups = ShoppingListView.group(entries, ShoppingGrouping.category);

      expect(<ShoppingCategory?>[for (final ShoppingGroup group in groups) group.category], <ShoppingCategory?>[
        food,
        cleaning,
        null,
      ]);
      expect(names(groups[1].entries), <String>['Lejía']);
      expect(names(groups[2].entries), <String>['Pilas']);
      expect(groups.every((ShoppingGroup group) => group.urgency == null), isTrue);
    });

    test('por categoría sin items sin categoría no añade ese grupo', () {
      expect(
        ShoppingListView.group(entries.where((ShoppingListEntry entry) => entry.item.name != 'Pilas').toList(),
                ShoppingGrouping.category)
            .map((ShoppingGroup group) => group.category),
        <ShoppingCategory?>[food, cleaning],
      );
    });

    test('por urgencia: de más a menos urgente, solo los niveles con items', () {
      final List<ShoppingGroup> groups = ShoppingListView.group(entries, ShoppingGrouping.urgency);

      expect(<Urgency?>[for (final ShoppingGroup group in groups) group.urgency], <Urgency?>[
        Urgency.immediate,
        Urgency.high,
        Urgency.normal,
        Urgency.low,
      ]);
      expect(names(groups.first.entries), <String>['Jabón', 'Queso']);
      expect(groups.every((ShoppingGroup group) => group.category == null), isTrue);
    });

    test('una lista vacía no tiene grupos', () {
      expect(ShoppingListView.group(<ShoppingListEntry>[], ShoppingGrouping.category), isEmpty);
      expect(ShoppingListView.group(<ShoppingListEntry>[], ShoppingGrouping.urgency), isEmpty);
    });
  });
}
