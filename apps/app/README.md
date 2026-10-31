# home_utility_app

App de utilidades del hogar. Es el punto de composición del monorepo: elige los adaptadores (almacenamiento, compartir, hardware, sincronización) y los plugins que se instalan, e inyecta todos sus textos. La lógica de cada funcionalidad vive en su plugin.

## Funcionalidades

- **Inicio:** los plugins activos, en lista (con sus tarjetas) o en grilla. En la grilla, un plugin con pantalla principal (`HomePluginEntryRoute`) se abre al tocarlo; los demás muestran su tarjeta en una hoja inferior.
- **Catálogo:** activar y desactivar plugins. La preferencia se guarda, y las rutas de un plugin desactivado, no disponible o que falló al iniciar quedan bloqueadas.
- **Configuración:** tema (claro, oscuro o del sistema), idioma (español o inglés) y vista del inicio.
- **Sincronización** (Configuración → Sincronización), entre los teléfonos de casa por la WiFi:
  - estado (última sincronización, cambios pendientes, dispositivos a la vista y el último error) y «Sincronizar ahora»;
  - hogar: crearlo y mostrar su código QR, unirse escaneándolo (o pegándolo), renombrar este dispositivo, ver los demás y salir. Solo el dispositivo que lo creó puede expulsar a otro: el hogar cambia de clave y el resto vuelve a escanear el código;
  - conflictos: cada uno con la resolución que ya rige y sus opciones. La elegida se sincroniza.

  Sincroniza al arrancar, al volver a primer plano, al ver otro dispositivo y poco después de cada cambio. En segundo plano se detiene.
- **Plugins instalados:**
  - Seguimiento de objetos (`plugin_item_tracker`): escanear, objetos, identificadores, contenedores y borrado.
  - Lista de compras (`plugin_shopping_list`): items, categorías, recurrencia y exportación.

## Estructura

- `lib/app_module_registrar.dart`: adaptadores elegidos (`appAdapters`: almacenamiento Isar, compartir, hardware y sincronización, con `SyncModule` al final) y plugins registrados (`appPluginFactories`).
- `lib/bootstrap.dart`: arranque testeable (`bootstrapApp`).
- `lib/plugins/plugin_controller.dart`: estado de los plugins para el inicio, el catálogo y el guard.
- `lib/navigation/`: router y `PluginRouteGuard`.
- `lib/home/`, `lib/catalog/` y `lib/settings/`.
- `lib/sync/`: pantallas de la sincronización. `SyncServices` toma del locator lo que registró `SyncModule`; sin él, Configuración no muestra la sección y el resto funciona igual.
- `assets/i18n/<paquete>/<idioma>.json`: todos los textos de los paquetes. Para cambiar un texto se edita aquí, no en el paquete.

Las preferencias de la app (tema, idioma) se guardan con `shared_preferences`, no en la base de datos de los plugins.

## Añadir un plugin

1. Añadir en `pubspec.yaml` el plugin y sus adaptadores.
2. Añadir sus adaptadores a `appAdapters` (p. ej. su `IsarFeature` dentro de `IsarStorage`).
3. Añadir su `PluginFactory` a `appPluginFactories`, registrando sus traducciones.
4. Añadir sus textos en `assets/i18n/<paquete>/` y el paquete a `injectedTranslationPackages`.

Sus rutas deben ser absolutas y compartir un primer segmento propio, que el guard usa como prefijo.

## Ejecutar

```sh
flutter run -d <id>
melos run build:apk       # APK de release en build/app/outputs/flutter-apk/app-release.apk
```

Configuración nativa: Android minSdk 24 y compileSdk 37. En iOS, `Info.plist` y `Runner.entitlements` (cámara, NFC), y el esquema `whatsapp` declarado en Android e iOS para detectar si está instalado.

Para la sincronización:
- **Android:** permisos `INTERNET`, `ACCESS_NETWORK_STATE` y `CHANGE_WIFI_MULTICAST_STATE`, y `android:allowBackup="false"`. Una copia restaurada en otro teléfono traería una clave del hogar que su Keystore no descifra y la identidad de este dispositivo.
- **iOS:** `NSLocalNetworkUsageDescription` y `NSBonjourServices` con `_hometasks._tcp`. Si el usuario niega el permiso de red local, no se ve a nadie.
- En el emulador de Android solo se ve a sí mismo: la sincronización se prueba con teléfonos en la misma WiFi.

## Tests

```sh
flutter test                                  # widget tests con AppHarness
flutter test integration_test -d <id>         # en dispositivo o simulador
```

- `AppHarness` (`test/helpers/app_harness.dart`) monta los plugins reales con hardware falso y repositorios en memoria.
- `ac02_persistence_test.dart` comprueba la persistencia con `IsarStorage` real, también con la sincronización compuesta (AC-10).
- `sync_test.dart` usa `SyncedDevice` (`test/helpers/synced_device.dart`): varios dispositivos con la sincronización sobre dobles en memoria y una red en memoria. Prueban crear el hogar, unirse, que los datos lleguen, expulsar, salir y la bandeja de conflictos.
- `injected_translations_test.dart` falla si falta en `assets/i18n/` alguna clave de un paquete.
