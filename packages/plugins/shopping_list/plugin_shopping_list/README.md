# plugin_shopping_list

Plugin de lista de compras (ID `shopping_list`, rutas bajo `/shopping-list`). Implementa `HomePlugin` y `HomePluginEntryRoute`, así que desde la grilla del inicio se abre directamente la lista.

## Qué hace

- **Items** con nombre, cantidad, notas, urgencia, categorías y recurrencia aproximada. Se crean, editan, marcan como comprados y borran. Al comprar aparece un aviso para deshacer, que se cierra a los 5 s. «Borrar comprados» limpia la lista y conserva los recurrentes.
- **Lista** filtrable por categorías, urgencia y estado (panel plegable), y agrupada por categoría o por urgencia.
- **Categorías:** cinco por defecto (Comida, Aseo, Limpieza, Hogar y Farmacia), que se pueden crear, renombrar, reordenar y borrar.
- **Recurrentes:** al comprarlos vuelven a la lista cuando se abre su ventana.
- **Exportar** la lista completa o la filtrada por WhatsApp, como texto o como archivo `.md`.
- **Tarjeta de inicio** con lo que hay por comprar y lo urgente.

## Integración

El plugin pide sus dependencias al `ServiceLocator`:
- `ShoppingListRepository` (obligatorio): lo registra el adaptador de almacenamiento que elige la app, p. ej. `ShoppingListIsar`.
- `ShareService` (opcional): sin él no se ofrece exportar.
- `EventBus`, `IdGenerator` y `Clock` (opcionales): si faltan, usa los suyos.

La app registra el plugin con `ShoppingListPlugin(locator: locator)..registerLocalization()` e inyecta sus textos desde `assets/i18n/shopping_list/`.

Mientras está activo, registra en su scope las capacidades `ShoppingListQuery` y `ShoppingListWriter` (`shopping_list_contract`) y publica `ShoppingItemPurchased` en el `EventBus`. Así otros plugins usan la lista sin depender de este paquete.

## Tests

- Casos de uso al 100 % (`test/domain/`).
- Pantallas con el plugin real y repositorio en memoria (`test/presentation/`).

## App de ejemplo

`example/` prueba el plugin en un dispositivo real. Consulta su README.
