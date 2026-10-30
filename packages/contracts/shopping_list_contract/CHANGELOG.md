# Changelog

## 0.1.1 - 2026-10-29

### Añadido

- README del paquete.

## 0.1.0 - 2026-10-28

### Añadido

- `ShoppingItemPurchased`: evento que la lista de compras publica en el `EventBus` al comprar un item.
- `ShoppingListQuery`: consulta de lo pendiente (`pendingItems` y `watchPendingItems`), con lo más urgente primero.
- `ShoppingListWriter`: añadir un item desde otro plugin (`addItem`). No duplica un pendiente con el mismo nombre: le sube la urgencia si hace falta y devuelve su ID.
- `ShoppingItemSummary` y `ShoppingItemRequest`: los datos que cruzan entre plugins. `ShoppingItemRequest` valida el nombre, y `ShoppingItemRequest.normalizeName` define cómo se comparan los nombres.
- Reexporta `Urgency` (paquete `urgency`).
- `package:shopping_list_contract/testing.dart`: la batería `shoppingListCapabilitiesContract` e `InMemoryShoppingList`, para los tests de quien usa la lista de compras.
