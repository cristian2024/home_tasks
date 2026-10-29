# Changelog

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
