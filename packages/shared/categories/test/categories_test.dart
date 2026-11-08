import 'package:categories/categories.dart';
import 'package:test/test.dart';

void main() {
  const ListCategory food = ListCategory(id: 'b', defaultKey: 'food', sortOrder: 0);
  const ListCategory garden = ListCategory(id: 'a', name: 'Jardín', sortOrder: 1);
  const ListCategory tied = ListCategory(id: 'c', name: 'Pagos', sortOrder: 1);
  String nameOf(ListCategory category) => category.name ?? 'Comida';

  test('una categoría necesita nombre o clave por defecto', () {
    expect(() => ListCategory(id: 'x', sortOrder: 0), throwsA(isA<AssertionError>()));
  });

  test('copyWith cambia nombre y orden, y conserva el resto', () {
    final ListCategory renamed = food.copyWith(name: 'Mercado', sortOrder: 4);

    expect(renamed, const ListCategory(id: 'b', name: 'Mercado', defaultKey: 'food', sortOrder: 4));
    expect(food.copyWith(), food);
    expect(food.toString(), contains('food'));
  });

  test('normaliza mayúsculas y espacios', () {
    expect(ListCategories.normalize('  Mi   Jardín '), 'mi jardín');
  });

  test('un nombre vacío o largo no vale', () {
    expect(ListCategories.problemWith(''), CategoryNameProblem.empty);
    expect(ListCategories.problemWith('a' * 41), CategoryNameProblem.tooLong);
    expect(ListCategories.problemWith('a' * 40), isNull);
  });

  test('detecta un nombre ocupado, salvo el de la propia categoría', () {
    const List<ListCategory> categories = <ListCategory>[food, garden];

    expect(ListCategories.isNameTaken(categories, ' comida ', nameOf: nameOf), isTrue);
    expect(ListCategories.isNameTaken(categories, 'Comida', nameOf: nameOf, exceptId: 'b'), isFalse);
    expect(ListCategories.isNameTaken(categories, 'Pagos', nameOf: nameOf), isFalse);
  });

  test('ordena por posición y, a igual posición, por ID', () {
    expect(ListCategories.sorted(<ListCategory>[tied, garden, food]), <ListCategory>[food, garden, tied]);
  });

  test('una categoría nueva va al final', () {
    expect(ListCategories.nextSortOrder(<ListCategory>[]), 0);
    expect(ListCategories.nextSortOrder(<ListCategory>[garden, food]), 2);
  });

  test('reordena con todos los IDs y rechaza listas incompletas', () {
    expect(ListCategories.reordered(<ListCategory>[food, garden], <String>['a', 'b']), <ListCategory>[
      garden.copyWith(sortOrder: 0),
      food.copyWith(sortOrder: 1),
    ]);
    expect(() => ListCategories.reordered(<ListCategory>[food, garden], <String>['a']), throwsArgumentError);
    expect(() => ListCategories.reordered(<ListCategory>[food, garden], <String>['a', 'z']), throwsArgumentError);
  });
}
