import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  late TestUseCases uc;

  setUp(() => uc = TestUseCases());

  test('EnsureDefaultShoppingCategories crea las categorías por defecto una sola vez', () async {
    expect(await uc.ensureDefaults(), isTrue);
    expect(await uc.ensureDefaults(), isFalse);

    expect(<String?>[for (final ShoppingCategory category in await uc.repository.getCategories()) category.defaultKey],
        <String>['food', 'hygiene', 'cleaning', 'home', 'pharmacy']);
  });

  group('CreateShoppingCategory', () {
    test('la añade al final con el nombre recortado', () async {
      await uc.ensureDefaults();

      final ShoppingCategory pets = await uc.createCategory(' Mascotas ');

      expect(pets.name, 'Mascotas');
      expect(pets.sortOrder, 5);
      expect((await uc.repository.getCategories()).last, pets);
    });

    test('la primera categoría va en la posición 0', () async {
      expect((await uc.createCategory('Comida')).sortOrder, 0);
    });

    test('rechaza un nombre que ya existe sin distinguir mayúsculas, también el de una por defecto', () async {
      await uc.ensureDefaults();
      await uc.createCategory('Mascotas');

      await expectLater(uc.createCategory('MASCOTAS'), throwsA(isA<ShoppingCategoryNameTakenException>()));
      await expectLater(uc.createCategory('food'), throwsA(isA<ShoppingCategoryNameTakenException>()));
      await expectLater(uc.createCategory(''), throwsA(isA<ShoppingValidationException>()));
    });
  });

  group('RenameShoppingCategory', () {
    test('cambia el nombre y conserva la clave por defecto', () async {
      await uc.ensureDefaults();
      final ShoppingCategory food = (await uc.repository.getCategories()).first;

      final ShoppingCategory renamed = await uc.renameCategory(food.id, 'Comestibles');

      expect(renamed, food.copyWith(name: 'Comestibles'));
      expect((await uc.repository.getCategories()).first, renamed);
    });

    test('con el mismo nombre no escribe; con el de otra lo rechaza', () async {
      final ShoppingCategory food = await uc.createCategory('Comida');
      await uc.createCategory('Hogar');

      expect(await uc.renameCategory(food.id, 'Comida'), food);
      expect(await uc.renameCategory(food.id, 'COMIDA'), food.copyWith(name: 'COMIDA'));
      await expectLater(uc.renameCategory(food.id, 'hogar'), throwsA(isA<ShoppingCategoryNameTakenException>()));
      await expectLater(uc.renameCategory('nada', 'x'), throwsA(isA<ShoppingCategoryNotFoundException>()));
    });
  });

  test('CountShoppingCategoryUsage y DeleteShoppingCategory', () async {
    final ShoppingCategory food = await uc.createCategory('Comida');
    final ShoppingCategory home = await uc.createCategory('Hogar');
    final ShoppingItem eggs = await uc.createItem(name: 'Huevos', categoryIds: <String>[food.id, home.id]);
    await uc.createItem(name: 'Pilas', categoryIds: <String>[home.id]);

    expect(await uc.countUsage(home.id), 2);
    expect(await uc.countUsage(food.id), 1);

    await uc.deleteCategory(home.id);

    expect(await uc.repository.getCategories(), <ShoppingCategory>[food]);
    expect((await uc.repository.getItem(eggs.id))!.categoryIds, <String>[food.id]);
    await expectLater(uc.deleteCategory(home.id), throwsA(isA<ShoppingCategoryNotFoundException>()));
  });

  test('ReorderShoppingCategories guarda el orden nuevo y exige todos los IDs', () async {
    final ShoppingCategory a = await uc.createCategory('A');
    final ShoppingCategory b = await uc.createCategory('B');

    await uc.reorder(<String>[b.id, a.id]);

    expect(await uc.repository.getCategories(), <ShoppingCategory>[b.copyWith(sortOrder: 0), a.copyWith(sortOrder: 1)]);
    await expectLater(uc.reorder(<String>[a.id]), throwsArgumentError);
    await expectLater(uc.reorder(<String>[a.id, 'nada']), throwsArgumentError);
  });
}
