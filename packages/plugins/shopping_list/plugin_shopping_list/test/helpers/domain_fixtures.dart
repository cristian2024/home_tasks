import 'package:core_events/testing.dart';
import 'package:core_utils/core_utils.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:plugin_shopping_list/testing.dart';

final DateTime t0 = DateTime.utc(2026, 10, 28, 9);

class TestIds implements IdGenerator {
  int _next = 1;

  @override
  String newId() => 'id-${_next++}';
}

/// Nombre de categoría para los tests: el propio o la clave por defecto.
String testCategoryName(ShoppingCategory category) => category.name ?? category.defaultKey!;

/// Casos de uso reales sobre un repositorio en memoria.
class TestUseCases {
  final InMemoryShoppingListRepository repository = InMemoryShoppingListRepository();
  final TestIds ids = TestIds();
  final FixedClock clock = FixedClock(t0);
  final RecordingEventBus eventBus = RecordingEventBus();

  CreateShoppingItem get createItem => CreateShoppingItem(repository, ids, clock);
  UpdateShoppingItem get updateItem => UpdateShoppingItem(repository, clock);
  GetShoppingItem get getItem => GetShoppingItem(repository);
  DeleteShoppingItems get deleteItems => DeleteShoppingItems(repository);
  MarkShoppingItemPurchased get markPurchased => MarkShoppingItemPurchased(repository, ids, clock, eventBus);
  UndoShoppingPurchase get undoPurchase => UndoShoppingPurchase(repository, clock);
  MarkShoppingItemPending get markPending => MarkShoppingItemPending(repository, clock);
  ClearPurchasedShoppingItems get clearPurchased => ClearPurchasedShoppingItems(repository);
  CreateShoppingCategory get createCategory => CreateShoppingCategory(repository, ids, testCategoryName);
  RenameShoppingCategory get renameCategory => RenameShoppingCategory(repository, testCategoryName);
  CountShoppingCategoryUsage get countUsage => CountShoppingCategoryUsage(repository);
  DeleteShoppingCategory get deleteCategory => DeleteShoppingCategory(repository, clock);
  ReorderShoppingCategories get reorder => ReorderShoppingCategories(repository);
  EnsureDefaultShoppingCategories get ensureDefaults => EnsureDefaultShoppingCategories(repository, ids);
  WatchShoppingList get watchList => WatchShoppingList(repository, clock);
  WatchShoppingCategories get watchCategories => WatchShoppingCategories(repository);

  ShoppingListApi get api => ShoppingListApi(
        repository: repository,
        clock: clock,
        createItem: createItem,
        markPending: markPending,
        categoryName: testCategoryName,
      );
}
