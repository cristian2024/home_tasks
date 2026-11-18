# plugin_shopping_list

Plugin de lista de compras (ID `shopping_list`, rutas bajo `/shopping-list`). Implementa `HomePlugin` y `HomePluginEntryRoute`, así que desde la grilla del inicio se abre directamente la lista.

## Qué hace

- **Ítems** con nombre, cantidad, notas, urgencia, categorías y recurrencia aproximada. Se crean seguidos desde un campo sobre el teclado (o con el formulario completo), se editan con el lápiz de la fila, se marcan como comprados y se borran deslizando la fila a la izquierda. Comprar, borrar y volver a pendiente ofrecen «Deshacer» durante 5 s.
- **Lista** de lo que hay que comprar (pendiente y atrasado, por defecto), con un panel de filtros fijo bajo la barra (categorías, urgencia, estado y agrupación por categoría o por urgencia).
- **Comprados y En espera:** filas al final de la lista que abren sus pantallas. En Comprados se vuelve a pendiente y se borran los comprados; en En espera se ve cuándo vuelve cada ítem y se puede comprar antes de tiempo.
- **Accesibilidad:** cada fila se lee como un solo botón con la acción «Borrar»; la lista anuncia lo que hay por comprar, las coincidencias al filtrar y lo creado.
- **Categorías:** cinco por defecto (Comida, Aseo, Limpieza, Hogar y Farmacia), que se pueden crear, renombrar, reordenar y borrar.
- **Recurrentes:** al comprarlos vuelven a la lista cuando se abre su ventana.
- **Exportar** la lista completa o la filtrada por WhatsApp, como texto o como archivo `.md`.
- **Tarjeta de inicio** con lo que hay por comprar y lo urgente.

## Integración

El plugin pide sus dependencias al `ServiceLocator`:
- `ShoppingListRepository` (obligatorio): lo registra el adaptador de almacenamiento que elige la app, p. ej. `ShoppingListIsar`.
- `ShareService` (opcional): sin él no se ofrece exportar.
- `ShoppingListPreferences` (opcional): preferencias del dispositivo. Sin ella, se guardan en memoria mientras la app está abierta; `shopping_list_shared_preferences` las guarda en el dispositivo.
- `EventBus`, `IdGenerator` y `Clock` (opcionales): si faltan, usa los suyos.

La app registra el plugin con `ShoppingListPlugin(locator: locator)..registerLocalization()` e inyecta sus textos desde `assets/i18n/shopping_list/`.

Mientras está activo, registra en su scope las capacidades `ShoppingListQuery` y `ShoppingListWriter` (`shopping_list_contract`) y publica `ShoppingItemPurchased` en el `EventBus`. Así otros plugins usan la lista sin depender de este paquete.

## Tests

- Casos de uso al 100 % (`test/domain/`).
- Pantallas con el plugin real y repositorio en memoria (`test/presentation/`).

## App de ejemplo

`example/` prueba el plugin en un dispositivo real. Consulta su README.
