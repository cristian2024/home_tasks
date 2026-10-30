# Changelog

## 1.5.2+9 - 2026-10-29

### Interno

- AC-02 arranca con un módulo de hardware falso, y los `integration_test` con los adaptadores de hardware reales, igual que `appAdapters`. Así los tests no dependen de que el plugin tenga sus propias implementaciones.

## 1.5.1+8 - 2026-10-29

### Añadido

- Adaptadores de hardware en `appAdapters`: `MobileScannerHardware` (cámara), `NfcManagerHardware` (NFC) y `PermissionHandlerHardware` (permisos). Registran `CameraIdentifierScanner`, `NfcIdentifierScanner` y `HardwarePermissions` en el `ServiceLocator`, para que los plugins los pidan de ahí.

## 1.5.0+7 - 2026-10-29

### Añadido

- Borrar objetos en el seguimiento de objetos (`plugin_item_tracker` 2.1.0): desde el detalle, con confirmación. Si el objeto contiene otros, se elige entre pasarlos a su contenedor o borrar todo. Sus textos están en `assets/i18n/item_tracker/`.
- README de la app: funcionalidades, estructura, cómo añadir un plugin, ejecución y tests.

### Cambiado

- item_tracker_isar 0.1.1: los objetos borrados se guardan marcados (`deletedAt`). Los datos ya guardados se siguen leyendo.

## 1.4.0+6 - 2026-10-28

### Añadido

- Plugin de lista de compras (`plugin_shopping_list` 0.1.0): su factoría en `appPluginFactories` y sus textos en `assets/i18n/shopping_list/`.
- Adaptadores: `ShoppingListIsar` dentro de `IsarStorage` y `NativeShare` (share_native 0.1.0) para exportar a WhatsApp, como texto o como archivo `.md`.
- WhatsApp declarado en `<queries>` (Android) y en `LSApplicationQueriesSchemes` (iOS), para que la app sepa si está instalado.
- En la grilla del inicio, un plugin con pantalla principal (`HomePluginEntryRoute` de core_contracts 0.1.2, como la lista de compras) se abre directamente al tocarlo. Los demás siguen mostrando su tarjeta en una hoja inferior.

### Cambiado

- core_contracts 0.1.2, core_events 0.1.1 y design_system 0.1.2.

### Interno

- `AppHarness` registra el `EventBus` en el scope raíz, como `bootstrapApp`, y puede incluir la lista de compras real (`includeShoppingList`).
- Tests de comunicación entre plugins: un plugin falso usa la lista de compras solo a través de `shopping_list_contract` y sigue funcionando cuando está desactivada.
- AC-02 también para la lista de compras; los `integration_test` usan los dos adaptadores Isar.

## 1.3.1+5 - 2026-10-27

### Cambiado

- La app solo elige sus adaptadores (`appAdapters` en `app_module_registrar.dart`): `IsarStorage` de storage_isar 0.2.0 con `ItemTrackerIsar` de item_tracker_isar 0.1.0. Cada adaptador abre la base y registra sus repositorios en el `ServiceLocator`; la app ya no abre Isar ni construye repositorios, y no depende de core_storage.
- `bootstrapApp` recibe `adapters` en lugar de `databaseDirectory` y `databaseName`. La base sigue en la carpeta de documentos con el mismo nombre y las mismas colecciones, así que los datos guardados se conservan.
- `AppEnvironment` ya no expone `isar`: la base se cierra al liberar el locator.
- core_di 0.1.1 e item_tracker 1.2.0.

### Interno

- Los widget tests registran el repositorio en memoria en el locator, como un adaptador. AC-02 y los `integration_test` usan los adaptadores reales en un directorio temporal.

## 1.3.0+4 - 2026-10-26

### Añadido

- Vista de accesos rápidos en el inicio: los plugins activos en una grilla (icono y título, 4 columnas en móvil), con «Añadir» siempre al final para abrir el catálogo. Un botón de la barra superior alterna entre lista y grilla.
- Al tocar un acceso rápido se abre la tarjeta del plugin en una hoja inferior, con todas sus acciones. Un plugin que no pudo iniciarse se ve con error y al tocarlo se reintenta.
- La vista elegida se guarda (`app.home_layout`) aparte de los plugins: cambiarla no modifica cuáles están activos ni su orden.

### Cambiado

- Usa design_system 0.1.1 (`AppShortcutTile`, `AppShortcutGrid`).

## 1.2.0+3 - 2026-10-24

### Cambiado

- La app define todos los textos de core_ui e item_tracker en `assets/i18n/<paquete>/<idioma>.json`, no solo los que cambian. Los inyecta con `injectTranslations` de core_ui 0.1.1.

### Interno

- Un test falla si a la app le falta un texto de un paquete, le sobra uno o cambia sus parámetros.

## 1.1.0+2 - 2026-10-24

### Añadido

- Los textos de core_ui e item_tracker se pueden reemplazar desde `assets/i18n/<paquete>/<idioma>.json`, solo con las claves que cambian (por ahora vacíos). Si un archivo no es válido se ignora y el paquete usa sus propios textos.

### Cambiado

- item_tracker 1.1.0.

### Interno

- Tipos explícitos en toda la app.
- Un test comprueba que cada clave reemplazada existe en el paquete, con el mismo tipo y los mismos parámetros.

## 1.0.0+1 - 2026-10-22

Primera versión con CHANGELOG. Incluye lo hecho hasta esa fecha:

### Añadido

- Pantalla de inicio con los módulos activos y catálogo para activarlos o desactivarlos.
- Las rutas de un módulo desactivado se bloquean.
- Configuración con tema, idioma y módulos, guardados en el dispositivo.
- Plugin item_tracker con persistencia local en Isar.
