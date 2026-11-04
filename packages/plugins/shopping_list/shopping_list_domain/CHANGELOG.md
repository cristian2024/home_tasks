# Changelog

## 0.2.0 - 2026-10-30

### Añadido

- Sincronización de la lista de compras (spec §10.4):
  - `ShoppingListCodec` y `ShoppingListCollections`: campos sincronizados de items, categorías y compras. `categoryIds` se fusiona como conjunto, elemento a elemento.
  - `ShoppingListResolver`: calcula, como función pura del estado, lo que lee la app y los conflictos. Une las categorías por defecto repetidas por `defaultKey` (queda la de id menor y sus items pasan a ella), ignora las categorías borradas en los items, oculta las compras de los items borrados y detecta la compra doble (`doublePurchase`): cuenta la de menor marca y el item toma su fecha. Todos los dispositivos llegan al mismo resultado sin escribir cambios nuevos.
  - `ShoppingListSyncStore`: contrato de las copias sincronizadas (`SyncedEntity`, de core_sync) que implementan los repositorios.
  - `ShoppingListSyncParticipant`: el `SyncParticipant` de la lista de compras. Resuelve la compra doble con escrituras normales del repositorio: con «una compra» borra la que no cuenta; con «dos compras» la registra como posterior a la otra.
- `InMemoryShoppingListRepository(hlcClock:, changeLog:)` se sincroniza: registra las escrituras locales e implementa `ShoppingListSyncStore`. Sin esos parámetros funciona igual que antes.
- `package:shopping_list_domain/testing.dart`: tests de contrato `shoppingListSyncContract` (incluye `syncParticipantContract`), los registros de ejemplo `shoppingListSyncRecords` y `readShoppingListState`.

### Cambiado

- **Incompatible:** los borrados son lógicos. `deleteItems` y `undoPurchase` reciben `deletedAt`. Lo borrado no aparece en ninguna consulta ni stream y no vuelve aunque se guarde otra vez con su ID (`saveItem`, `saveCategories`, `recordPurchase`). Toda implementación debe adaptarse.
- `shoppingListRepositoryContract` comprueba que lo borrado no vuelve y que `undoPurchase` de una compra que no existe solo restaura el item.
- Depende de core_sync 0.1.1 y core_utils 0.1.1.

## 0.1.1 - 2026-10-29

### Añadido

- README del paquete.

## 0.1.0 - 2026-10-28

### Añadido

- Entidades `ShoppingItem` (nombre, notas, cantidad, urgencia, estado, categorías, recurrencia y última compra), `ShoppingCategory` (con `DefaultShoppingCategory` para las que se crean por defecto) y `ShoppingPurchase` (historial de compras).
- `ShoppingItem.stateAt(now)`: estado que se muestra (`overdue`, `pending`, `waiting` o `purchased`), según el estado guardado y la recurrencia.
- `ShoppingListView`:
  - `entries`: une cada item con su estado y sus categorías;
  - `compare`: orden dentro de un grupo, primero lo atrasado y lo pendiente, y lo más urgente;
  - `group`: agrupa por categoría (cada item una sola vez, bajo su primera categoría; «Sin categoría» al final) o por urgencia.
- `ShoppingListFilter`: filtra por categorías («cualquiera de», con o sin los items sin categoría), urgencias y estados.
- `ShoppingValidator`: límites de nombre, notas, cantidad y nombre de categoría, y `normalize` para comparar nombres.
- Errores `sealed ShoppingListException`: `ShoppingItemNotFoundException`, `ShoppingCategoryNotFoundException`, `ShoppingCategoryNameTakenException` y `ShoppingValidationException`.
- Contrato `ShoppingListRepository`, con operaciones atómicas para borrar una categoría en uso, registrar y deshacer una compra, y crear las categorías por defecto una sola vez.
- `package:shopping_list_domain/testing.dart`: batería `shoppingListRepositoryContract` e `InMemoryShoppingListRepository`.
- Reexporta los paquetes `recurrence` y `urgency`.
