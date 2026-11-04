# shopping_list_contract

API pública de la lista de compras para otros plugins. Es Dart puro y es lo único que un plugin necesita importar para hablar con la lista: nunca depende de `plugin_shopping_list`.

## Contenido

- **Evento** `ShoppingItemPurchased` (`itemId`, `itemName`, `purchasedAt`): la lista lo publica en el `EventBus` al comprar un item.
- **Capacidades**, que la lista registra en su scope del `ServiceLocator` mientras está activa:
  - `ShoppingListQuery`: lo pendiente (`pendingItems()` y `watchPendingItems()`), con lo más urgente primero.
  - `ShoppingListWriter.addItem(request)`: añade un item y devuelve su ID. No duplica un pendiente con el mismo nombre: si hace falta le sube la urgencia y devuelve el ID que ya tenía.
- **Datos que cruzan:**
  - `ShoppingItemRequest`: nombre, cantidad, notas y urgencia. Valida el nombre, y `normalizeName` define cómo se comparan los nombres.
  - `ShoppingItemSummary`: lo pendiente, con sus categorías y si está atrasado.
- Reexporta `Urgency` (paquete `urgency`).

## Uso

Pedir la capacidad al usarla, sin guardarla, y seguir funcionando si la lista está desactivada:

```dart
if (locator.isRegistered<ShoppingListWriter>()) {
  await locator.get<ShoppingListWriter>().addItem(ShoppingItemRequest(name: 'Pilas AA', urgency: Urgency.high));
}
```

Para reaccionar a las compras, escuchar `ShoppingItemPurchased` con un `EventSubscriptions` (`core_events`).

## Tests

`package:shopping_list_contract/testing.dart` trae la batería `shoppingListCapabilitiesContract`, que pasa la implementación real, e `InMemoryShoppingList`, para los tests de quien usa la lista.

```sh
dart test
```
