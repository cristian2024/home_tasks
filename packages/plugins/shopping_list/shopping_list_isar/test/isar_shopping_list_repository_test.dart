import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:shopping_list_domain/testing.dart';
import 'package:shopping_list_isar/shopping_list_isar.dart';
import 'package:shopping_list_isar/src/repositories/isar_shopping_list_repository.dart';
import 'package:storage_isar/adapter.dart';

import 'helpers/isar_fixtures.dart';

void main() {
  setUpAll(() => Isar.initializeIsarCore(download: true));

  final Map<ShoppingListRepository, TestStorage> storages = <ShoppingListRepository, TestStorage>{};
  shoppingListRepositoryContract(
    'Isar',
    create: () async {
      final TestStorage storage = await TestStorage.open();
      storages[storage.repository] = storage;
      return storage.repository;
    },
    dispose: (ShoppingListRepository repository) => storages.remove(repository)!.close(),
  );

  test('ShoppingListIsar aporta sus colecciones y registra su repositorio Isar', () async {
    final TestStorage storage = await TestStorage.open();
    addTearDown(storage.close);

    expect(
      const ShoppingListIsar().schemas.map((CollectionSchema<dynamic> schema) => schema.name),
      <String>['IsarShoppingItem', 'IsarShoppingCategory', 'IsarShoppingPurchase', 'IsarShoppingListFlag'],
    );
    expect(storage.repository, isA<IsarShoppingListRepository>());
  });
}
