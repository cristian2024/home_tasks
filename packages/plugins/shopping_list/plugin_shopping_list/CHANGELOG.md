# Changelog

## 0.3.0 - 2026-11-17

### Añadido

- El panel de filtros queda fijo bajo la barra y la lista se desplaza debajo. Mide como mucho la mitad de la pantalla, muestra 4 categorías y «N más», y termina en «Restablecer» y «Listo · N».
- «Añadir ítem» abre un campo sobre el teclado: Intro crea el ítem y vacía el campo. Un chip dice en qué categoría irá (la del filtro si es una sola; si no, la última usada) y permite cambiarla sin cerrar el teclado. El ítem nuevo se resalta y la lista baja hasta él.
- Deslizar una fila a la izquierda la borra, sin diálogo y con «Deshacer». La fila tiene también la acción «Borrar» para los lectores de pantalla. La primera vez que se borra desde editar, el aviso sugiere el gesto.
- Lápiz al final de cada fila para editar. La fila se lee como un solo botón con su nombre, sus datos y «Editar».
- Pantallas «Comprados» (con la fecha de compra, volver a pendiente con «Deshacer» y «Borrar comprados») y «En espera» (cuándo vuelve cada ítem y comprar antes de tiempo), a las que se llega desde las filas «Comprados · N» y «En espera · N» al final de la lista.
- Estado «Todo comprado», distinto de la lista vacía, con «Ver comprados».
- Anuncios para lectores de pantalla: lo que hay por comprar al abrir, cuántos ítems coinciden al filtrar, el ítem creado y el cambio de categoría del campo.
- Casos de uso `RestoreShoppingItem` (vuelve a crear un ítem borrado, para «Deshacer») y `RevertShoppingItem`.
- Toma `ShoppingListPreferences` del `ServiceLocator` si la app la registra; si no, la guarda en memoria.

### Cambiado

- **Incompatible:** la lista empieza con el filtro Pendiente + Atrasado. «En espera» y «Comprado» se ven al activarlos en el filtro o en sus pantallas. Al marcar un ítem como comprado, su fila desaparece.
- **Incompatible:** `ShoppingListDependencies` pide `restoreItem`, `revertItem` y `preferences`.
- **Incompatible:** el formulario, al borrar, hace `pop` con el ítem borrado en lugar de sin resultado.
- La barra superior tiene Filtros y ⋮. El ⋮ abre una hoja con Categorías y Exportar; «Borrar comprados» pasa a la pantalla Comprados.
- «item» pasa a «ítem» en todos los textos.
- Depende de design_system 0.3.2 y shopping_list_domain 0.2.2.

### Eliminado

- La clave `shopping_list.list.filters_active` («Hay filtros activos.»).

## 0.2.3 - 2026-11-08

### Interno

- Los casos de uso de categorías usan `ListCategories` para el nombre ocupado, la posición de una nueva y la reordenación.

## 0.2.2 - 2026-11-05

### Cambiado

- Los iconos pasan a la familia lineal de `AppIcons`.
- La urgencia alta se muestra en rojo, como la inmediata.
- Con la lista vacía no se muestran compartir ni filtros. Si nada coincide con los filtros, el aviso va centrado y sin la franja de filtros activos.
- «Guardar» queda fijo al pie del formulario. El botón de añadir categoría es rectangular y las acciones de cada fila, más discretas.
- La hoja de exportar mide lo que su contenido.

### Interno

- Usa `design_system` 0.3.0.

## 0.2.1 - 2026-11-04

### Cambiado

- La tarjeta del inicio usa `AppModuleCard`.
- La barra de la lista deja a la vista Exportar y Filtros. Categorías y Borrar comprados pasan a un menú.
- Exportar marca Compartir archivo y Guardar archivo como botones con borde.
- El formulario quita los iconos de los selectores y pone el mínimo y el máximo de días en una fila.
- Categorías añade con un botón de icono y agrupa la lista en una tarjeta.
- `recurrence_range` pasa a «Entre X e Y». Clave nueva: `more_actions`.

## 0.2.0 - 2026-10-30

### Cambiado

- **Incompatible:** reexporta shopping_list_domain 0.2.0, cuyos borrados son lógicos (`deleteItems` y `undoPurchase` reciben `deletedAt`).
- Borrar items, «Borrar comprados» y deshacer una compra pasan la fecha del borrado al repositorio. `DeleteShoppingItems` y `ClearPurchasedShoppingItems` aceptan un `Clock` (por defecto, `SystemClock`).

## 0.1.1 - 2026-10-29

### Añadido

- README del paquete.

## 0.1.0 - 2026-10-28

### Añadido

- `ShoppingListPlugin` (ID `shopping_list`, rutas bajo `/shopping-list`): lista de compras con items (nombre, cantidad, notas, urgencia, categorías y recurrencia aproximada) que se crean, editan, marcan como comprados (con deshacer) y borran.
- Lista filtrable por categorías, urgencia y estado, agrupada por categoría (cada item una vez, bajo su primera categoría) o por urgencia, con lo urgente y lo atrasado a la vista.
- Gestión de categorías con cinco por defecto (Comida, Aseo, Limpieza, Hogar y Farmacia): crear, renombrar, reordenar y borrar. Al borrar una en uso se avisa de cuántos items la usan, y esos items conservan sus demás categorías.
- Items recurrentes: al comprarlos guardan la fecha en el historial y vuelven a la lista cuando se abre su ventana.
- Exportar la lista completa o la filtrada, agrupada por categoría o por urgencia: por WhatsApp, como texto, o como archivo `.md` (compartir o guardar). Usa el `ShareService` que registre la app; sin él no se ofrece exportar.
- Capacidades públicas `ShoppingListQuery` y `ShoppingListWriter` (`shopping_list_contract`), registradas en el scope del plugin mientras está activo, y el evento `ShoppingItemPurchased` en el `EventBus`.
- Tarjeta de inicio con lo que hay por comprar y lo urgente. Implementa `HomePluginEntryRoute` (`/shopping-list`), así que desde la grilla del inicio la lista se abre directamente.
- Textos en español e inglés que la app puede reemplazar (`translation_overrides`).
- App de ejemplo en `example/`, que elige sus adaptadores (`ShoppingListIsar` y `NativeShare`) e inyecta todos los textos.

### Interno

- `WatchShoppingList` combina los streams de items y categorías con `Rx.combineLatest2` (rxdart).
