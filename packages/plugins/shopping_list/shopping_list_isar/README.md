# shopping_list_isar

Adaptador Isar de la lista de compras. Implementa `ShoppingListRepository` (`shopping_list_domain`) y pasa sus tests de contrato, también los de la sincronización.

## Uso

Quien compone la app solo lo elige, dentro de `IsarStorage` (`storage_isar`):

```dart
IsarStorage(features: <IsarFeature>[ShoppingListIsar()])
```

Con la base abierta, `ShoppingListIsar` registra `ShoppingListRepository` en el `ServiceLocator`, y el plugin lo pide de ahí. También añade su `ShoppingListSyncParticipant` a `SyncParticipants`, en el scope raíz, para que un plugin desactivado siga recibiendo cambios.

## Sincronización

Solo se activa si la app compuso la sincronización: `SyncIsar` dentro de `IsarStorage` y el `HlcClock` de `SyncModule` en el locator. Entonces cada escritura actualiza su copia sincronizada y registra sus cambios en la misma transacción. La primera vez migra lo guardado antes (spec §10.4.8). Sin la sincronización compuesta, no registra nada.

## Datos

- Colecciones:
  - `IsarShoppingItem`, con índice multiEntry en `categoryIds`;
  - `IsarShoppingCategory`;
  - `IsarShoppingPurchase`;
  - `IsarShoppingListFlag`, que marca, p. ej., que las categorías por defecto ya se crearon;
  - `IsarShoppingListSynced`, las copias sincronizadas.
- Los borrados son lógicos (`deletedAt`) y las consultas solo devuelven lo activo.
- Las escrituras que tocan varias entidades van en una sola transacción: borrar una categoría en uso, registrar o deshacer una compra y crear las categorías por defecto.

## Tests

Usan Isar real (`Isar.initializeIsarCore(download: true)`).

```sh
flutter test --coverage
```

Cobertura de los mappers: 100 %.
