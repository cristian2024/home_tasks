import 'package:fake_async/fake_async.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:shopping_list_domain/testing.dart';
import 'package:test/test.dart';

void main() {
  shoppingListRepositoryContract(
    'InMemory',
    create: InMemoryShoppingListRepository.new,
    dispose: (ShoppingListRepository repository) => (repository as InMemoryShoppingListRepository).close(),
  );

  test('first termina con el reloj simulado (onCancel no devuelve el futuro de cancel)', () {
    fakeAsync((FakeAsync async) {
      final InMemoryShoppingListRepository repository = InMemoryShoppingListRepository();
      List<ShoppingItem>? items;
      List<ShoppingCategory>? categories;

      repository.watchItems().first.then((List<ShoppingItem> value) => items = value);
      repository.watchCategories().first.then((List<ShoppingCategory> value) => categories = value);
      async.flushMicrotasks();

      expect(items, isEmpty);
      expect(categories, isEmpty);
    });
  });
}
