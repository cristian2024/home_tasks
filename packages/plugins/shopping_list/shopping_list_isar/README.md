# shopping_list_isar

Adaptador Isar de la lista de compras. Implementa `ShoppingListRepository` (`shopping_list_domain`) y pasa su batería de contrato.

## Uso

Quien compone la app solo lo elige, dentro de `IsarStorage` (`storage_isar`):

```dart
IsarStorage(features: <IsarFeature>[ShoppingListIsar()])
```

Con la base abierta, `ShoppingListIsar` registra `ShoppingListRepository` en el `ServiceLocator`, y el plugin lo pide de ahí.

## Datos

- Colecciones:
  - `IsarShoppingItem`, con índice multiEntry en `categoryIds`;
  - `IsarShoppingCategory`;
  - `IsarShoppingPurchase`;
  - `IsarShoppingListFlag`, que marca, p. ej., que las categorías por defecto ya se crearon.
- Las escrituras que tocan varias entidades van en una sola transacción: borrar una categoría en uso, registrar o deshacer una compra y crear las categorías por defecto.

## Tests

Usan Isar real (`Isar.initializeIsarCore(download: true)`).

```sh
flutter test --coverage
```

Cobertura de los mappers: 100 %.
