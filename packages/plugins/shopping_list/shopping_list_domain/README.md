# shopping_list_domain

Dominio de la lista de compras, en Dart puro: entidades, reglas, errores y el contrato del repositorio.

## Contenido

- **Entidades:**
  - `ShoppingItem`: nombre, notas, cantidad, urgencia, estado, categorías, recurrencia y última compra.
  - `ShoppingCategory`, con `DefaultShoppingCategory` para las que se crean por defecto.
  - `ShoppingPurchase`: el historial de compras.
- **`ShoppingItem.stateAt(now)`**: el estado que se muestra (`overdue`, `pending`, `waiting` o `purchased`), según el estado guardado y la recurrencia (`recurrence`).
- **`ShoppingListView`**: une cada item con su estado y sus categorías (`entries`), los ordena (`compare`: primero lo atrasado y lo urgente) y los agrupa (`group`) por categoría o por urgencia. Por categoría, cada item aparece una sola vez, bajo su primera categoría, y «Sin categoría» va al final.
- **`ShoppingListFilter`**: por categorías, urgencias y estados.
- **`ShoppingValidator`**: límites de los campos y `normalize` para comparar nombres.
- **Errores:** `sealed ShoppingListException` (`ShoppingItemNotFoundException`, `ShoppingCategoryNameTakenException`…).
- **Contrato `ShoppingListRepository`**, con operaciones atómicas: borrar una categoría en uso, registrar y deshacer una compra, y crear las categorías por defecto una sola vez.

Reexporta `recurrence` y `urgency`.

## Implementar el repositorio

Toda implementación debe pasar `shoppingListRepositoryContract`, de `package:shopping_list_domain/testing.dart`. El mismo archivo trae `InMemoryShoppingListRepository`.

## Tests

```sh
dart test
```

Cobertura: 100 %.
