# home_utility_app

App de utilidades del hogar. Es el punto de composición del monorepo: elige los adaptadores (almacenamiento, compartir, hardware, sincronización) y los plugins que se instalan, e inyecta todos sus textos. La lógica de cada funcionalidad vive en su plugin.

## Funcionalidades

- **Inicio:** los plugins activos, en lista (con sus tarjetas) o en grilla. En la grilla, un plugin con pantalla principal (`HomePluginEntryRoute`) se abre al tocarlo; los demás muestran su tarjeta en una hoja inferior.
- **Catálogo:** activar y desactivar plugins. La preferencia se guarda, y las rutas de un plugin desactivado, no disponible o que falló al iniciar quedan bloqueadas.
- **Accesos rápidos del icono:** al mantener pulsado el icono de la app aparecen los plugins del inicio con pantalla principal (como mucho 4, en su orden) y cada uno la abre directamente. Se actualizan al activar o desactivar plugins y al cambiar de idioma. Si el plugin ya no está activo, la app abre el inicio con un aviso.
- **Espacios de datos** (Configuración → Espacios): cada espacio es un conjunto de datos con su propia base, local o de un hogar de sincronización, con sus propios plugins activos. Se puede cambiar de espacio, crear uno (eligiendo antes su nombre), renombrarlo y borrar los que no están en uso. El inicio lleva como título el nombre del espacio abierto, salvo en el inicial, que conserva el de la app. Al cambiar, la app vuelve a empezar con los datos de ese espacio; solo se sincroniza el abierto.
- **Configuración:** tema (claro, oscuro o del sistema), idioma (español o inglés) y vista del inicio.
- **Sincronización** (Configuración → Sincronización), entre los teléfonos de casa por la WiFi:
  - estado (última sincronización, cambios pendientes, dispositivos a la vista y el último error) y «Sincronizar ahora»;
  - hogar: crearlo y mostrar su código, como QR y como texto para copiarlo o compartirlo; unirse escaneándolo o pegándolo (sin permiso para la cámara, «Dar permiso» lo vuelve a pedir); renombrar este dispositivo, ver los demás y salir. Solo el dispositivo que lo creó puede expulsar a otro: el hogar cambia de clave y el resto vuelve a escanear el código;
  - conflictos: cada uno con la resolución que ya rige y sus opciones. La elegida se sincroniza.

  Sincroniza al arrancar, al volver a primer plano, al ver otro dispositivo y poco después de cada cambio. En segundo plano se detiene.
- **Plugins instalados:**
  - Seguimiento de objetos (`plugin_item_tracker`): escanear, objetos, identificadores, contenedores y borrado.
  - Lista de compras (`plugin_shopping_list`): items, categorías, recurrencia y exportación.

## Estructura

- `lib/app_module_registrar.dart`: adaptadores elegidos y plugins registrados (`appPluginFactories`). Los del dispositivo (`deviceAdapters`: lista de espacios y accesos rápidos) se componen una vez; los de cada espacio (`appAdaptersFor(space:)`: su base Isar, compartir, hardware y sincronización, con `SyncModule` al final), cada vez que se abre.
- `lib/bootstrap.dart`: arranque testeable de un espacio (`bootstrapApp`).
- `lib/spaces/`: espacios de datos. `bootstrapSpaces` elige el espacio activo (en el primer arranque, uno sobre la base de siempre, sin copiar datos) y borra las bases de espacios borrados a medias. `SpaceSwitcher` cambia de espacio: libera el entorno, abre el otro y solo entonces lo marca como activo; si falla, vuelve a abrir el anterior. `SpaceRoot` muestra la app del espacio abierto y `SpaceHouseholdTracker` anota en la lista el hogar de cada espacio.
- `lib/plugins/plugin_controller.dart`: estado de los plugins para el inicio, el catálogo y el guard.
- `lib/navigation/`: router y `PluginRouteGuard`.
- `lib/home/`, `lib/catalog/` y `lib/settings/`.
- `lib/shortcuts/`: `AppShortcutsPublisher`, que publica los accesos rápidos con el `AppShortcutService` que registró un adaptador, y `AppShortcutDefaults` (límite e iconos por plugin).
- `lib/sync/`: pantallas de la sincronización. `SyncServices` toma del locator lo que registró `SyncModule`; sin él, Configuración no muestra la sección y el resto funciona igual.
- `assets/i18n/<paquete>/<idioma>.json`: todos los textos de los paquetes. Para cambiar un texto se edita aquí, no en el paquete.

Las preferencias de la app (tema, idioma) se guardan con `shared_preferences`, no en la base de datos de los plugins.

## Añadir un plugin

1. Añadir en `pubspec.yaml` el plugin y sus adaptadores.
2. Añadir sus adaptadores a `appAdaptersFor` (p. ej. su `IsarFeature` dentro de `IsarStorage`).
3. Añadir su `PluginFactory` a `appPluginFactories`, registrando sus traducciones.
4. Añadir sus textos en `assets/i18n/<paquete>/` y el paquete a `injectedTranslationPackages`.
5. Si tiene pantalla principal (`HomePluginEntryRoute`), sale en los accesos rápidos del icono. Para darle icono, añadir su recurso nativo y su entrada en `AppShortcutDefaults.icons`.

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

Para los accesos rápidos, el icono de cada plugin es un recurso nativo con el nombre de `AppShortcutDefaults.icons`: `res/drawable/shortcut_<plugin>.xml` en Android y `Assets.xcassets/shortcut_<plugin>.imageset` en iOS. `res/raw/keep.xml` evita que el build de release de Android lo quite, porque quick_actions lo busca por nombre.

## Tests

```sh
flutter test                                  # widget tests con AppHarness
flutter test integration_test -d <id>         # en dispositivo o simulador
```

- `AppHarness` (`test/helpers/app_harness.dart`) monta los plugins reales con hardware falso y repositorios en memoria.
- `ac02_persistence_test.dart` comprueba la persistencia con `IsarStorage` real, también con la sincronización compuesta (AC-10).
- `sync_test.dart` usa `SyncedDevice` (`test/helpers/synced_device.dart`): varios dispositivos con la sincronización sobre dobles en memoria y una red en memoria. Prueban crear el hogar, unirse, que los datos lleguen, expulsar, salir y la bandeja de conflictos.
- `spaces_test.dart` usa `SpacePhone` (`test/helpers/space_phone.dart`): teléfonos con Isar real, la lista de espacios en memoria y el arranque real. Prueba la migración, cambiar de espacio sin mezclar datos ni plugins, la vuelta atrás si un espacio no abre, crear un hogar o unirse en otro espacio (y «¿llevar los datos?») y borrar espacios.
- `app_shortcuts_test.dart` usa `AppHarness(shortcuts: FakeAppShortcutService())`: qué accesos se publican y cuándo, y qué abre cada pulsación (también en frío).
- `injected_translations_test.dart` falla si falta en `assets/i18n/` alguna clave de un paquete.
