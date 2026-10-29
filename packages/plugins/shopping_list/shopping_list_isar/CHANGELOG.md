# Changelog

## 0.1.0 - 2026-10-28

### Añadido

- `ShoppingListIsar`: `IsarFeature` de `storage_isar` para la lista de compras. Quien compone la app solo lo elige; con la base abierta registra `ShoppingListRepository` en el `ServiceLocator`.
- Su implementación Isar pasa `shoppingListRepositoryContract`. Las escrituras de varias entidades (borrar una categoría en uso, registrar o deshacer una compra, crear las categorías por defecto) van en una sola transacción.
- Colecciones `IsarShoppingItem` (con índice multiEntry en `categoryIds`), `IsarShoppingCategory`, `IsarShoppingPurchase` e `IsarShoppingListFlag`.
