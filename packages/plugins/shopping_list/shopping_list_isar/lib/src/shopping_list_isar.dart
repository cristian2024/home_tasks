import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:storage_isar/adapter.dart';

import 'models/isar_shopping_category.dart';
import 'models/isar_shopping_item.dart';
import 'models/isar_shopping_list_flag.dart';
import 'models/isar_shopping_list_synced.dart';
import 'models/isar_shopping_purchase.dart';
import 'repositories/isar_shopping_list_repository.dart';

/// Adaptador Isar de la lista de compras. Quien compone la app solo lo elige,
/// dentro de `IsarStorage(features: <IsarFeature>[ShoppingListIsar()])`,
/// también si el plugin está desactivado.
///
/// Con la base abierta registra `ShoppingListRepository` en el
/// `ServiceLocator` y añade su `ShoppingListSyncParticipant` a
/// `SyncParticipants`, en el scope raíz: un plugin desactivado sigue
/// recibiendo sus cambios. Si la app no compuso la sincronización, no se
/// registra nada en el log.
class ShoppingListIsar implements IsarFeature {
  const ShoppingListIsar();

  @override
  List<CollectionSchema<dynamic>> get schemas => const <CollectionSchema<dynamic>>[
        IsarShoppingItemSchema,
        IsarShoppingCategorySchema,
        IsarShoppingPurchaseSchema,
        IsarShoppingListFlagSchema,
        IsarShoppingListSyncedSchema,
      ];

  @override
  void register(ServiceLocator services, Isar isar) {
    final IsarShoppingListRepository repository = IsarShoppingListRepository(isar, services: services);
    services.registerSingleton<ShoppingListRepository>(repository);
    SyncParticipants.of(services).add(ShoppingListSyncParticipant(store: repository, repository: repository));
  }
}
