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
- **Contrato `ShoppingListRepository`**, con operaciones atómicas: borrar una categoría en uso, registrar y deshacer una compra, y crear las categorías por defecto una sola vez. Los borrados son lógicos (`deletedAt`): lo borrado no aparece y no vuelve aunque se guarde con su ID.

## Sincronización

Los cambios viajan entre dispositivos (spec §10.4) con estas piezas:

- **`ShoppingListCodec`** convierte items, categorías y compras en campos sincronizados (colecciones `ShoppingListCollections`). `categoryIds` es un conjunto: dos dispositivos que añaden categorías distintas al mismo item conservan las dos.
- Cada repositorio guarda, aparte de las entidades, su **copia sincronizada** (`SyncedEntity`, de core_sync). Las escrituras locales la actualizan y registran sus cambios en la misma transacción. Para eso implementa también `ShoppingListSyncStore`.
- **`ShoppingListResolver`** calcula lo que se ve a partir de las copias, como función pura:
  - categorías por defecto repetidas (cada dispositivo sembró las suyas): queda la de id menor y sus items pasan a ella;
  - una categoría borrada mientras otro la añadía a un item: la referencia se ignora;
  - las compras de un item borrado no se muestran;
  - **compra doble**: dos compras del mismo item hechas sin saber una de la otra (registran la misma compra anterior, `previousPurchaseId`) y, si el item se repite, a menos de `minDays` días. Cuenta la de menor marca y aparece el conflicto `doublePurchase` («¿fueron dos compras?»).
  - Dos items o dos categorías con el mismo nombre no son conflicto: quedan los dos.
- **`ShoppingListSyncParticipant`** es el `SyncParticipant`: fusiona los cambios recibidos, aplica el resolver y guarda el resultado. Al resolver la compra doble, «una compra» borra la que no cuenta y «dos compras» la registra como posterior a la otra.

Reexporta `recurrence` y `urgency`.

## Implementar el repositorio

Toda implementación debe pasar los tests de contrato `shoppingListRepositoryContract`, de `package:shopping_list_domain/testing.dart`. Si se sincroniza, también `shoppingListSyncContract`, con su participante. El mismo archivo trae `InMemoryShoppingListRepository`, que se sincroniza si recibe `hlcClock` y `changeLog`.

## Tests

```sh
dart test
```

Cobertura: 100 %.
