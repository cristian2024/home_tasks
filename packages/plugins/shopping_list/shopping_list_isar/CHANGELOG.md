# Changelog

## 0.1.2 - 2026-10-30

### Añadido

- Sincronización con `sync_isar`, si la app la compuso (hay `HlcClock` e `IsarChangeLogWriter` en el locator):
  - cada escritura local actualiza las copias sincronizadas (colección nueva `IsarShoppingListSynced`) y registra sus cambios en la misma transacción;
  - `IsarShoppingListRepository` implementa `ShoppingListSyncStore` y pasa `shoppingListSyncContract`;
  - `ShoppingListIsar` añade su `ShoppingListSyncParticipant` a `SyncParticipants` en el scope raíz, así que un plugin desactivado sigue recibiendo sus cambios.
- Migración (spec §10.4.8): la primera vez que se sincroniza, lo guardado antes recibe su copia y sus registros de cambio, con marcas derivadas de sus fechas. Lo borrado se migra borrado, las categorías (sin fecha) reciben la marca más antigua y las compras de cada item se encadenan por fecha. Se hace una sola vez.

### Cambiado

- Los borrados son lógicos: items, categorías y compras tienen un campo nuevo `deletedAt`, `null` en los datos ya guardados, que se siguen leyendo.
- shopping_list_domain 0.2.0, storage_isar 0.2.1 y core_di 0.1.2. Depende además de core_sync 0.1.1, core_utils 0.1.1 y sync_isar 0.1.0.

## 0.1.1 - 2026-10-29

### Añadido

- README del paquete.

## 0.1.0 - 2026-10-28

### Añadido

- `ShoppingListIsar`: `IsarFeature` de `storage_isar` para la lista de compras. Quien compone la app solo lo elige; con la base abierta registra `ShoppingListRepository` en el `ServiceLocator`.
- Su implementación Isar pasa `shoppingListRepositoryContract`. Las escrituras de varias entidades (borrar una categoría en uso, registrar o deshacer una compra, crear las categorías por defecto) van en una sola transacción.
- Colecciones `IsarShoppingItem` (con índice multiEntry en `categoryIds`), `IsarShoppingCategory`, `IsarShoppingPurchase` e `IsarShoppingListFlag`.
