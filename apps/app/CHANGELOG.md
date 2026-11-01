# Changelog

## 1.8.0+12 - 2026-10-31

### Añadido

- Varios espacios de datos (Configuración → Espacios): cada uno es local o de un hogar, con su propia base Isar y sus propios plugins activos. Cambiar de espacio vuelve a empezar la app con sus datos; solo se sincroniza el abierto. Se pueden crear, renombrar y borrar (salvo el abierto, que nunca se borra).
- Crear un hogar o unirse a uno pregunta, si el espacio abierto no tiene hogar, si sus datos van al hogar o se empieza un espacio vacío. Unirse a un hogar que ya tiene espacio cambia a él; desde el espacio de otro hogar, se une en uno nuevo.
- Avisos al cambiar de espacio (al que se ha cambiado, que elija los plugins de un espacio nuevo, o que no se pudo abrir) y el nombre del espacio en Sincronización.

### Cambiado

- `appAdapters` pasa a ser `appAdaptersFor({space, deviceName})`; la lista de espacios y los accesos rápidos van en `deviceAdapters`, que se componen una vez y sobreviven a los cambios de espacio. `bootstrapApp` recibe `device` y `space`.
- El primer arranque crea un espacio sobre la base de siempre: los datos, la sincronización y las preferencias de los plugins se siguen leyendo sin copiar nada, y su hogar se anota en la lista.
- `core_spaces`, `spaces_shared_preferences`, `storage_isar` ^0.2.2 y `sync_engine` ^0.1.2 (una clave por hogar). `core_secrets` pasa a dependencia.

### Interno

- `SpacePhone` en los tests: teléfonos con Isar real y el arranque real con espacios.

## 1.7.0+11 - 2026-10-31

### Añadido

- Accesos rápidos del icono de la app (pulsación larga en el lanzador de Android e iOS): los plugins del inicio con pantalla principal, como mucho 4 y en su orden, con su nombre traducido. Cada uno abre su pantalla principal, también con la app cerrada. Se actualizan al activar o desactivar plugins y al cambiar de idioma.
- `appAdapters` incluye `QuickActionsShortcuts` (`app_shortcuts_quick_actions`). `bootstrapApp` crea `AppShortcutsPublisher` si hay un `AppShortcutService` registrado y `AppEnvironment.dispose()` lo libera.
- Icono del acceso de la lista de compras como recurso nativo (Android `res/drawable`, iOS `Assets.xcassets`) y `res/raw/keep.xml` para que el build de release no lo quite.

### Interno

- `AppHarness` acepta `shortcuts:` (p. ej. `FakeAppShortcutService`).

## 1.6.0+10 - 2026-10-31

### Añadido

- Sincronización entre los dispositivos de casa por la WiFi, en Configuración → Sincronización: estado y «Sincronizar ahora», hogar (crear y mostrar su código QR, unirse escaneándolo o pegándolo, renombrar este dispositivo, ver los demás, salir y, solo el creador, expulsar) y bandeja de conflictos.
- `appAdapters` compone la sincronización: `SyncIsar` dentro de `IsarStorage`, `SecureStorageSecrets`, `CryptographySyncCipher`, `LanSyncTransport` y `SyncModule` al final. `bootstrapApp` arranca el controlador y la app lo pausa en segundo plano y lo reanuda al volver.
- Permisos de red en Android y `NSLocalNetworkUsageDescription` y `NSBonjourServices` en iOS.

### Cambiado

- Android no hace copias de seguridad de la app (`allowBackup="false"`): la clave del hogar no se descifraría en otro teléfono y la copia duplicaría la identidad del dispositivo.
- `item_tracker_isar` ^0.1.2 y `shopping_list_isar` ^0.1.2, que registran los cambios para la sincronización. `plugin_shopping_list` pasa a ^0.2.0 (borrados lógicos). `design_system` ^0.1.4.

### Interno

- `SyncedDevice` en los tests: varios dispositivos con la sincronización sobre dobles en memoria. `AppHarness` acepta repositorios y la sincronización.

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
