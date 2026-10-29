import 'package:core_share/core_share.dart';

import 'domain/use_cases/build_shopping_export.dart';
import 'domain/use_cases/category_use_cases.dart';
import 'domain/use_cases/item_use_cases.dart';
import 'domain/use_cases/list_queries.dart';
import 'domain/use_cases/purchase_use_cases.dart';

/// Todo lo que necesitan las pantallas del plugin. El plugin lo registra en
/// su scope de `core_di` durante `initialize()`.
class ShoppingListDependencies {
  const ShoppingListDependencies({
    required this.createItem,
    required this.updateItem,
    required this.getItem,
    required this.deleteItems,
    required this.markPurchased,
    required this.undoPurchase,
    required this.markPending,
    required this.clearPurchased,
    required this.createCategory,
    required this.renameCategory,
    required this.countCategoryUsage,
    required this.deleteCategory,
    required this.reorderCategories,
    required this.watchList,
    required this.watchCategories,
    required this.buildExport,
    required this.shareService,
    required this.now,
  });

  final CreateShoppingItem createItem;
  final UpdateShoppingItem updateItem;
  final GetShoppingItem getItem;
  final DeleteShoppingItems deleteItems;
  final MarkShoppingItemPurchased markPurchased;
  final UndoShoppingPurchase undoPurchase;
  final MarkShoppingItemPending markPending;
  final ClearPurchasedShoppingItems clearPurchased;
  final CreateShoppingCategory createCategory;
  final RenameShoppingCategory renameCategory;
  final CountShoppingCategoryUsage countCategoryUsage;
  final DeleteShoppingCategory deleteCategory;
  final ReorderShoppingCategories reorderCategories;
  final WatchShoppingList watchList;
  final WatchShoppingCategories watchCategories;
  final BuildShoppingExport buildExport;

  /// El `ShareService` que haya registrado la app, buscado en el momento de
  /// usarlo; `null` si no hay (y entonces no se ofrece exportar).
  final ShareService? Function() shareService;

  /// Hora actual (UTC), del `Clock`.
  final DateTime Function() now;
}
