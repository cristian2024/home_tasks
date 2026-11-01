# CLAUDE.md - Guía de Desarrollo para Claude Code

## Comandos del Monorepo (Melos)
- **Instalación/Bootstrap:** `melos bs`
- **Análisis estático:** `melos run analyze` (`tool/analyze.dart`: falla con cualquier problema salvo las reglas en adopción gradual, que solo cuenta por proyecto)
- **Ejecutar pruebas:** `melos run test`[cite: 1]
- **Generar código (Isar / Slang):** `melos run gen` (`gen:isar` + `gen:i18n`). `melos bs` lo ejecuta al terminar.
- **Código generado:** los `*.g.dart` no se versionan (`.gitignore`). Después de cambiar de rama o tocar un modelo Isar o un JSON de traducciones, ejecutar `melos run gen`. Los paquetes que aún tengan generados versionados los sacan del índice (`git rm --cached`) en la primera rama que los toque.
- **build_runner y `example/`:** un paquete con `build_runner` y app de ejemplo debe tener un `build.yaml` que excluya `example/**`. Si no, build_runner sigue `example/ios/.symlinks` hasta `~/.pub-cache` y borra archivos de otros paquetes.
- **Generar APK de release (apps/app):** `melos run build:apk` → `apps/app/build/app/outputs/flutter-apk/app-release.apk`

---

## Reglas Arquitectónicas Estrictas
1. **Clean Architecture (Capa Domain):**
   - La capa `domain` de cualquier paquete o plugin **nunca** debe importar paquetes de Flutter (`package:flutter/...`) ni motores de base de datos (`package:isar/...`)[cite: 1].
2. **Aislamiento entre Plugins:**
   - Los paquetes situados en `packages/plugins/*` **nunca** deben importar otros paquetes dentro de `packages/plugins/*`[cite: 1].
3. **Identificadores y Tiempos:**
   - Usar **UUID v4** obligatoriamente para todas las entidades de dominio (prohibido usar IDs autoincrementales numéricos para dominio)[cite: 1].
   - Todas las estampas de tiempo (`DateTime`) deben almacenarse y manipularse estrictamente en **UTC** (`DateTime.now().toUtc()`)[cite: 1].
4. **Hardware e Infraestructura:**
   - La lógica de hardware (Cámara/NFC) debe aislarse detrás de los contratos de `packages/core/core_hardware`; las implementaciones están en los adaptadores `packages/adapters/hardware_*`. La capa de presentación o dominio no debe invocar SDKs nativos directamente[cite: 1].

---

## Stack Tecnológico Clave
- **Framework:** Flutter (>=3.27.0) / Dart[cite: 1]
- **Gestión de Estado:** `flutter_bloc` / `Cubit`[cite: 1]
- **Navegación:** `go_router` (enrutamiento declarativo)[cite: 1]
- **Base de Datos Local:** `isar_community`, solo en los adaptadores (`storage_isar`, `<funcionalidad>_isar`); el resto del código usa repositorios abstractos[cite: 1]
- **Internacionalización:** `slang` (archivos JSON por paquete bajo namespace)[cite: 1]
- **Inyección de Dependencias:** `get_it` (`core_di`)[cite: 1]

---

## Convenciones de Código
- Nombres de archivos y carpetas en **snake_case**[cite: 1].
- Excluir archivos generados (`*.g.dart`, `*.i18n.json`) del linter según `analysis_options.yaml`[cite: 1].
- Todo componente interactivo de UI debe incluir accesibilidad (`Semantics` o `tooltip`)[cite: 1].
- **Tipos explícitos:** tipar siempre las variables (`final String name = …`, no `final name = …`). La regla `always_specify_types` es obligatoria: `melos run analyze` falla con cualquier caso. `toleratedCodes` (`tool/analyze.dart`) queda vacío; sirve para adoptar poco a poco una regla nueva.
- **Sin funciones que devuelven widgets:** evitar métodos como `Widget _buildX()` o `List<Widget> _section()`; extraer una clase de widget (privada si solo divide una pantalla). No hay lint de Dart para esto: se revisa a mano.
- **Expresiones repetidas:** si una expresión se usa más de una vez, guardarla en una variable local y usarla en todos los sitios. P. ej., un estilo del tema (`theme.textTheme.bodyMedium`) va en una variable al principio de `build` (`final TextStyle? bodyStyle = …`), un dato que se calcula de otro (`entity.uri.pathSegments.last`), en `final String fileName = …`, y un campo que se lee varias veces (`state.plugin`), en `final HomePlugin plugin = state.plugin;`. Dentro de un literal de colección (`<String>{ for … if … }`) no se pueden declarar variables: usar un bucle normal que vaya llenando la colección.
- **Campos del widget en un `State`:** si el estado (`build`, otro método o el inicializador de un campo) lee varias veces el mismo `widget.x`, declarar un getter privado (`double? get _size => widget.size;`) y usarlo en todos los sitios. También cuenta si cada lectura va a un subcampo distinto (`widget.environment.sync`, `widget.environment.settings` → `AppEnvironment get _environment => widget.environment;`).
- **Constantes en su archivo:** los valores por defecto o literales que se repiten (colores, márgenes, tamaños) van en un archivo propio con una `abstract final class` (p. ej. `QrDefaults` en `qr_defaults.dart`, como los tokens de `design_system`), no escritos a mano en cada constructor.
- **Widgets reutilizables agnósticos:** un widget con una función concreta que pueda usarse en otro sitio recibe por parámetros todo lo que necesita y devuelve resultados con callbacks. No usa cubits ni blocs, navegación, diálogos ni snackbars: eso lo hace la screen, que los conecta. Las partes privadas en que se divide una screen para leerla mejor (`_DetailBody`, `_CameraView`…) son parte de la screen.
- **Una rama por proyecto:** cada rama (y su PR) cambia un solo proyecto: un paquete de `packages/`, una app de `apps/` o la raíz (`pubspec.yaml`, `tool/`, `.github/`, CLAUDE.md, specs). Los paquetes de una misma funcionalidad (`packages/plugins/<funcionalidad>/`: `_domain`, `plugin_` con su `example/` y sus adaptadores) cuentan como un solo proyecto y se cambian en la misma rama. Cada uno sigue subiendo su versión y su CHANGELOG.
- **Versión y CHANGELOG por paquete (§5.3):** toda rama que cambie un paquete (o `apps/app`) sube su `version:` y añade una entrada a su `CHANGELOG.md`. Se adopta poco a poco: el primer cambio a un paquete que aún no tiene CHANGELOG lo crea. Las apps de `example/`, `tool/` y la raíz no llevan.
  - **SemVer.** En `0.x.y`, un cambio incompatible sube el minor (`0.1.0` → `0.2.0`) y cualquier otro el patch (`0.1.0` → `0.1.1`). A partir de `1.0.0`, major / minor / patch. En `apps/app` se sube además el build (`+n`).
  - **Dependientes.** Entre paquetes del workspace se usa `^x.y.z`, nunca `any`. Si una subida deja fuera la restricción de un dependiente (un cambio incompatible), la misma rama la actualiza en todos los `pubspec.yaml` que dependen del paquete, con su ejemplo y `apps/app`. Esto y las claves de traducción nuevas (ver «Clave nueva» en la Fase 4) son las únicas excepciones a una rama por proyecto. El dependiente no sube de versión por eso: lo anota en su siguiente entrada.
  - **Formato:** una entrada por rama, `## <versión> - <AAAA-MM-DD>`, con los cambios agrupados por tipo, en este orden y omitiendo los vacíos:
    - `Añadido`: funcionalidad nueva.
    - `Cambiado`: cambios en algo que ya existía.
    - `Obsoleto`: lo que se eliminará en una versión futura.
    - `Eliminado`: lo que se quitó.
    - `Corregido`: errores arreglados.
    - `Seguridad`: vulnerabilidades corregidas.
    - `Interno`: refactors, tests o tooling sin cambio de comportamiento (p. ej. tipos explícitos).
  - Cada cambio es una línea que dice qué cambia para quien usa el paquete. Los incompatibles empiezan por `**Incompatible:**`.
  - En un plugin, `HomePlugin.version` coincide con la `version:` de su `pubspec.yaml`.

---

## Monorepo (Fase 1)
- **Melos 8 + Dart pub workspaces:** no existe `melos.yaml`; la configuración de Melos vive en la sección `melos:` del `pubspec.yaml` raíz. Cada paquete nuevo declara `resolution: workspace` y debe quedar cubierto por la lista `workspace:` de la raíz.
- Si `melos` falla con "Invalid kernel binary format": `dart pub global activate melos`.
- **Verificación completa antes de dar algo por terminado:** `melos run verify` (analyze + verify:arch + test).
- **Reglas de importación (§5.2):** `melos run verify:arch` ejecuta `tool/verify_architecture.dart` (lógica en `tool/src/`, tests en `tool/test/`). Las reglas 8 a 10: un contrato (`packages/contracts/*`) es Dart puro y no importa funcionalidades ni apps; solo los adaptadores importan `share_plus`, `url_launcher`, `file_picker`, `path_provider` o `quick_actions` (regla 9) y las librerías de la sincronización: `bonsoir`, `cryptography` y `flutter_secure_storage` (regla 10).
- **Plugins:** implementan `HomePlugin` (`core_contracts`), incluido `isAvailable()`. Si tienen una pantalla principal, implementan además `HomePluginEntryRoute` (`entryRoute`): la grilla del inicio la abre directamente en lugar de mostrar su tarjeta en una hoja. El ciclo de vida lo aplica `PluginLifecycleManager`; las preferencias se persisten vía `PluginPreferenceRepository`.
- **DI:** usar `ServiceLocator` de `core_di`, nunca `get_it` directamente. Cada plugin registra sus dependencias en un scope con su ID (`pushScope`) y lo libera en `dispose()` (`dropScope`).
- **Igualdad por valor:** extender `Equatable` (paquete `equatable`) y declarar `props`; nunca sobrescribir `operator ==`/`hashCode` a mano. Aplica a entidades, value objects y estados de BLoC/Cubit.

## Fase 2 (persistencia y hardware)
- **Funcionalidades con datos:** cada una es una carpeta `packages/plugins/<funcionalidad>/` (no un paquete) con tres paquetes:
  - `<funcionalidad>_domain`: Dart puro. Entidades, contrato del repositorio, errores y reglas; en `testing.dart`, la batería de tests de contrato y el repositorio en memoria.
  - `plugin_<funcionalidad>`: el `HomePlugin`. Casos de uso, UI, rutas e i18n, y su app de `example/`. Nunca importa su adaptador.
  - `<funcionalidad>_<motor>` (p. ej. `item_tracker_isar`): el adaptador. Modelos del motor, mappers y repositorio, que pasa la batería de contrato.
- **Adaptadores y composición:** los adaptadores transversales van en `packages/adapters/` (`storage_isar`). Quien compone (la app o un ejemplo) solo elige adaptadores, una lista de `DependencyModule` (`core_di`): `IsarStorage(features: <IsarFeature>[ItemTrackerIsar()])`. Cada adaptador abre sus recursos y registra en el `ServiceLocator` sus implementaciones con el tipo del contrato (`PluginPreferenceRepository`, `HouseholdItemRepository`). Plugins y app las piden al locator. Lo que abre lo registra con `dispose`, y `locator.reset()` lo libera.
- **Cambiar de motor** (p. ej. a SQLite): un `storage_<motor>` y un `<funcionalidad>_<motor>` por funcionalidad que pase su batería de contrato. Fuera de ellos solo cambia la lista de adaptadores de quien compone.
- **Isar:** usar `isar_community` fijado en 3.3.2 (nunca `isar`). Los adaptadores de funcionalidad importan su API desde `package:storage_isar/adapter.dart`, que la reexporta, e implementan `IsarFeature` (`schemas` y `register`). `IsarStorage` lleva los `IsarFeature` de **todos** los plugins registrados, también los desactivados. Los adaptadores conservan los nombres de colección y de base de datos para que los datos ya guardados se sigan leyendo.
- **Tests con Isar:** `setUpAll(() => Isar.initializeIsarCore(download: true))`, con `Isar` de `package:storage_isar/adapter.dart`. Descarga `libisar.dylib` en el paquete (está en `.gitignore`).
- **Hardware:** la presentación usa solo `CameraIdentifierScanner`, `NfcIdentifierScanner` y `HardwarePermissions`. La cámara se muestra con `buildPreview()`. Las implementaciones están en los adaptadores `hardware_mobile_scanner`, `hardware_nfc_manager` y `hardware_permission_handler`. Quien compone los elige y registran los contratos en el `ServiceLocator`; los escáneres, como factorías (un escáner nuevo en cada `get`). Los plugins los piden al locator, y sus constructores aceptan sustitutos. En tests usar los fakes de `package:core_hardware/testing.dart`.
- **Regla 4 del verificador:** solo los adaptadores (`packages/adapters/hardware_*`) importan `mobile_scanner`, `nfc_manager*` o `permission_handler`.
- **IDs y tiempo:** inyectar `IdGenerator` (`UuidV4Generator`) y `Clock` (`SystemClock`, `FixedClock` en tests) de `core_utils` en lugar de llamar a `Uuid()` o `DateTime.now()` en dominio y data.
- **ID del plugin de objetos:** `item_tracker` (scope DI, preferencia y namespace i18n); su ruta base es `/item-tracker`.
- **App de ejemplo de hardware:** `packages/core/core_hardware/example`, que elige los adaptadores `hardware_*`. Sirve de referencia para la configuración nativa de `apps/app`: Android minSdk 24 y compileSdk 37; en iOS, `Info.plist` y `Runner.entitlements`. Los plugins de iOS usan Swift Package Manager: **no** escribir un Podfile a mano. Si un plugin no admite SPM (p. ej. `isar_community_flutter_libs`), Flutter genera el Podfile solo para él y se versionan `Podfile` y `Podfile.lock`.
- **Widget tests con streams:** después de emitir desde un fake, usar `await tester.pumpAndSettle()`. Con un solo `pump()` el evento llega después del frame.

## Fase 3 (UI base y plugin item_tracker)
- **i18n:** cada paquete tiene `slang.yaml` y `lib/src/i18n/{es,en}.i18n.json`. Se regenera con `dart run slang` en el paquete (no con build_runner). Con `lazy: false` y `enum_name`/`class_name`/`translate_var` propios del paquete. Registrar el paquete en `LocalizationCoordinator.instance` y usar `commonStrings.common.*` para textos comunes.
- **UI:** usar los componentes de `design_system` (`AppButton`, `AppIconButton` con tooltip, `AppTextField`, `AppStatusView`…) en lugar de los widgets Material sueltos.
- **Plugin item_tracker:** las reglas de negocio están en el §9.4 de la spec (validación, rechazo de identificadores ya asociados, eventos técnicos automáticos). Los errores de dominio son el `sealed` `ItemTrackerException`.
- **Isar nativo:** una violación de índice único llega como `IsarError` con "Unique index violated", no como `IsarUniqueViolationError` (ese es solo para web).
- **mocktail:** `captureAny` captura los argumentos con nombre en orden alfabético.
- **Cobertura:** deben quedar al 100 % (`flutter test --coverage`) los casos de uso (plugin), el paquete `<funcionalidad>_domain` (incluida la jerarquía) y los mappers (adaptador, p. ej. `item_tracker_isar`).
- **Contenedores (item_tracker):** `HouseholdItem.parentId`; la jerarquía se calcula con `ItemTree` y los límites con `ContainmentPolicy` (máx. 5 niveles, `--dart-define=ITEM_TRACKER_MAX_DEPTH`). Ambos viven en `item_tracker_domain`. Detalle en el §9.4 de la spec.
- **Plugin item_tracker (presentación):** `ScanBloc` para el escaneo y Cubits para el resto. Las pantallas devuelven resultados con `context.pop(itemId)` (ver §12.1). En los tests de widgets usar `PluginHarness` (`test/helpers/presentation_fixtures.dart`), que monta el plugin real con hardware falso y repositorio en memoria.

## Trampas conocidas en tests
- **Handlers de bloc:** no hacer `await` de `subscription.cancel()` ni de `dispose()` de escáneres dentro de un handler. En `testWidgets` esos futuros no se completan con el reloj simulado y el bloc se queda bloqueado. Lanzarlos con `unawaited`.
- **`blocTest`:** cierra el bloc antes de `verify`. Comprobar dentro de `act` el estado que el cierre cambia (p. ej. escáneres liberados).
- **`tester.pageBack()`:** busca el tooltip en inglés. Con la app en español, usar `tester.tap(find.byType(BackButton))`.
- **`pumpAndSettle`:** nunca termina con indicadores de carga animados visibles. Usar `pump()`.
- **`SnackBar`:** llamar a `hideCurrentSnackBar()` antes de `showSnackBar` para que no se queden en cola.
- **Isar y el binding de tests:** `TestWidgetsFlutterBinding` responde 400 a todas las peticiones HTTP. En un test que necesite el binding (p. ej. para `rootBundle`), ejecutar `Isar.initializeIsarCore(download: true)` **antes** de `TestWidgetsFlutterBinding.ensureInitialized()`. Si no, en CI (sin `libisar` en caché) la descarga falla. Ver `apps/app/test/ac02_persistence_test.dart`.
- **`onCancel` de un stream:** en un `StreamController` que reenvía otra suscripción, `onCancel` no debe devolver el futuro de su `cancel()`. `Stream.first` lo espera y, en `testWidgets`, no se completa con el reloj simulado: el test se cuelga. Cancelar sin devolverlo (ver `InMemoryHouseholdItemRepository`).
- **`first` sobre streams de rxdart:** operadores como `Rx.combineLatest2` devuelven en su `onCancel` el futuro de las cancelaciones, y `first` lo espera. En `testWidgets` no termina (p. ej. `WatchShoppingList().first`). Para leer una vez, usar el repositorio (`getItems()`…).
- **Streams contra una base real:** esperar la emisión inicial antes de escribir, con `StreamQueue` y `emitsThrough`. Con `take(n).toList()` y una escritura inmediata, la escritura compite con la consulta inicial y el test falla de forma intermitente (pasaba en local y fallaba en la CI de Ubuntu).

## Fase 4 (apps/app)
- **Estructura:**
  - `lib/app_module_registrar.dart`: adaptadores elegidos (`deviceAdapters`, una vez; `appAdaptersFor(space:)`, en cada espacio) y registro de plugins (`appPluginFactories`).
  - `lib/bootstrap.dart`: arranque testeable (`bootstrapApp`).
  - `lib/plugins/plugin_controller.dart`: estado de los plugins para inicio, catálogo y guard.
  - `lib/navigation/`: router y `PluginRouteGuard`.
  - `lib/home/`, `lib/catalog/` y `lib/settings/` (configuración: tema, idioma, acceso al catálogo).
- **Preferencias de la app** (tema, idioma): `shared_preferences` vía `AppSettingsRepository`, nunca en la base de datos (es de los plugins). `bootstrapApp` recibe `systemLanguageCode` y aplica el idioma guardado si el usuario fijó uno. En tests, `InMemoryAppSettingsRepository` (`test/helpers/`) o `SharedPreferences.setMockInitialValues`.
- **Añadir un plugin:**
  1. Añadir en `apps/app/pubspec.yaml` la dependencia del plugin y la de sus adaptadores (p. ej. `item_tracker_isar`).
  2. Añadir sus adaptadores en `appAdaptersFor` (p. ej. su `IsarFeature` dentro de `IsarStorage`).
  3. Añadir una `PluginFactory` en `appPluginFactories`. La factoría debe registrar las traducciones del plugin (como `registerLocalization()` de item_tracker).
  4. Sus rutas deben ser absolutas y compartir un primer segmento propio (el guard lo usa como prefijo).
  5. Si implementa `HomePluginEntryRoute`, sale en los accesos rápidos del icono. Su icono es un recurso nativo (`res/drawable/shortcut_<plugin>.xml` y `Assets.xcassets/shortcut_<plugin>.imageset`) con su entrada en `AppShortcutDefaults.icons`.
- **Accesos rápidos del icono:** contrato `AppShortcutService` (`core_app_shortcuts`, con `FakeAppShortcutService` y `appShortcutServiceContract` en `testing.dart`) y adaptador `QuickActionsShortcuts` (`app_shortcuts_quick_actions`). `AppShortcutsPublisher` (`apps/app/lib/shortcuts/`) publica los plugins del inicio con pantalla principal (como mucho 4) y los vuelve a publicar al cambiar los plugins o el idioma. La app escucha las pulsaciones tras el primer frame; la del arranque en frío la guarda el servicio. En los tests, `AppHarness(shortcuts: FakeAppShortcutService())`.
- **Idioma:**
  - Envolver con `LanguageRebuilder` (`core_ui`) el contenido de las rutas. El router de la app ya lo hace con `withLanguageRebuild`.
  - Sin eso, las páginas abiertas no cambian de idioma, porque los textos de slang son globales y GoRouter conserva su `Navigator` con una `GlobalKey`.
  - Para traducir claves de otros paquetes: `LocalizationCoordinator.translate(key)`.
- **Textos de los paquetes (§13.2):** quien consume los paquetes (`apps/app` y las apps de ejemplo) define **todos** sus textos en `assets/i18n/<paquete>/<idioma>.json` y los inyecta al arrancar con `injectTranslations` (core_ui). Para cambiar un texto, editar el archivo del consumidor, no el JSON del paquete, que es contrato y respaldo.
  - **Clave nueva:** añadirla al JSON del paquete y, **en la misma rama**, a cada consumidor (`apps/app` y las apps de ejemplo). Si falta, `test/injected_translations_test.dart` falla (`translationProblems` de `package:core_ui/testing.dart`). Como la CI ejecuta los tests de todo el workspace, dejarlo para la rama de la app bloquea el PR del paquete.
  - **Paquete nuevo con textos:** activa `translation_overrides: true` en su `slang.yaml` y pasa `override:` al registrarse. Cada consumidor lo añade a su `injectedTranslationPackages`, con sus archivos en `assets/i18n/` y su paquete Dart en el test.
- **Tests de la app:**
  - `AppHarness` (`test/helpers/app_harness.dart`): plugin real con hardware falso, repositorios en memoria y `FakeHomePlugin` configurable.
  - AC-02 con `IsarStorage` real en `test/ac02_persistence_test.dart`.
  - En dispositivo o simulador: `cd apps/app && flutter test integration_test -d <id>`.
- **`HomeUtilityApp`:** crea su router con el primer `AppEnvironment`. Para simular un reinicio en un test, usar `key: ObjectKey(environment)`.
- **CI:** `.github/workflows/ci.yml`, en Ubuntu. En `main` ejecuta `melos run verify`. En un PR, `analyze` y `verify:arch` de todo el workspace y `test:changed` (`tool/test_changed.sh`): los paquetes cambiados respecto a `origin/main` y sus dependientes, o todo si cambia algo fuera de `packages/` y `apps/` que no sea documentación. Los dependientes cuentan: un cambio en un paquete ejecuta también los tests de la app (p. ej. `injected_translations_test`). Si se sube la versión de Flutter o Melos, actualizarla también ahí.
- **Archivos del editor:** `.vscode/` no se versiona (es configuración personal). Para que la extensión Dart encuentre los proyectos Flutter anidados, cada desarrollador pone `"dart.projectSearchDepth": 6` en su configuración.

## Fase 5 (comunicación entre plugins y lista de compras)
- **Comunicación entre plugins (§11.2):** eventos para hechos (`EventBus`) y capacidades para consultas y acciones (interfaces registradas en el `ServiceLocator`). No hay bus de comandos.
  - **Contratos:** un paquete por funcionalidad que publica, en `packages/contracts/<funcionalidad>_contract`, con todos sus eventos, capacidades y datos que cruzan. Un evento nuevo es una clase más, no un paquete nuevo. Su `testing.dart` trae la batería de las capacidades y un doble en memoria.
  - **Publicar:** el plugin dueño registra sus capacidades en su scope (`pushScope(pluginId)`), así desaparecen con su `dispose()`. Publica en el `EventBus` del scope raíz, con `emittedAt` de su `Clock`.
  - **Consumir:** depender solo del contrato. Pedir la capacidad al locator al usarla (`isRegistered<T>()` y `get<T>()`), nunca guardarla en `initialize()`; si falta, ocultar o degradar sin error. Escuchar eventos con un `EventSubscriptions` registrado en el scope propio con `dispose: (EventSubscriptions s) => s.cancelAll()`.
  - Los eventos no se guardan: lo publicado mientras un plugin está desactivado se pierde. Para el estado actual, una capacidad.
  - En los tests de la app, `AppHarness(includeShoppingList: true)` monta la lista de compras real. Ejemplo de consumidor: `apps/app/test/cross_plugin_communication_test.dart`.
- **Paquetes comunes en `packages/shared/`:** `urgency` (niveles), `recurrence` (ventana mínimo–máximo de días y sus estados) y `list_export` (formateadores para WhatsApp y Markdown). Son Dart puro y van al 100 % de cobertura.
- **Compartir:** contrato `ShareService` (`core_share`, con `FakeShareService` y `shareServiceContract` en `testing.dart`) y adaptador `NativeShare` (`share_native`). Para detectar WhatsApp, la app declara el esquema `whatsapp` en `<queries>` (Android) y en `LSApplicationQueriesSchemes` (iOS).
- **Plugin lista de compras (§9.5):** ID `shopping_list`, rutas bajo `/shopping-list`. Reglas de negocio, estado derivado (`ShoppingItem.stateAt`) y agrupación (`ShoppingListView`) en `shopping_list_domain`. Las categorías son propias del plugin. En los tests de widgets, `PluginHarness` (`test/helpers/presentation_fixtures.dart`) con repositorio en memoria, `RecordingEventBus` y `FakeShareService`.
- **Apps de ejemplo de plugins:** el workspace las cubre con el glob `packages/plugins/*/plugin_*/example`.
- **Workspace y globs:** pub rechaza un glob de `workspace:` que no coincide con ningún paquete. La rama que crea el primer paquete de una carpeta nueva añade su glob.

## Fase 6 (sincronización entre dispositivos)
- **Diseño:** §10.4 de la spec. P2P en la WiFi de casa, cifrado de extremo a extremo, gossip con vectores de versiones y un HLC por campo. Isar sigue siendo la fuente de verdad: sin red, la app funciona igual.
- **Paquetes:**
  - `hlc` (Dart puro): reloj lógico híbrido.
  - `core_sync` (contratos, Dart puro): registros de cambio, vector, hogar, conflictos y los contratos `SyncTransport`, `SyncParticipant`, `SyncCipher`, `ChangeLog`, `SyncStateRepository` y `ConflictRepository`. En `testing.dart`, sus tests de contrato, los dobles en memoria, `InMemorySyncNetwork` (con cortes de red) y `FakeSyncCipher` (no es seguro).
  - `core_secrets`: contrato `SecretStore`.
  - `sync_engine`: motor, bandeja, hogar, controlador y `SyncModule`. En `testing.dart`, `SyncSimulator` y `SimulatedDevice`.
  - Adaptadores: `sync_isar`, `sync_lan`, `sync_crypto_cryptography` y `secret_store_secure_storage`.
  - `qr_display`: `AppQrCode`, con `qr` y un `CustomPainter` (no `qr_flutter`).
- **Composición:** `SyncIsar()` va dentro de `IsarStorage`, y `SyncModule()` va **al final** de `appAdaptersFor`, porque compone el motor con lo que registraron los demás. Transportes y participantes se añaden con `SyncTransports.of(services).add(...)` y `SyncParticipants.of(services).add(...)` en el scope raíz. `bootstrapApp` llama a `SyncController.start()`; la app lo pausa en segundo plano y lo reanuda al volver. Sin `SyncModule`, `SyncServices.of(locator)` es `null` y Configuración no muestra la sección.
- **Una funcionalidad que se sincroniza:**
  - Las entidades no llevan metadatos. El repositorio guarda una copia sincronizada por entidad (`SyncedEntity`) y, en la misma transacción que la escritura, registra el cambio con `LocalSyncRecorder` (en Isar, con `IsarChangeLogWriter`). Los casos de uso no cambian.
  - Los borrados son lógicos (`deletedAt`): sin eso, un borrado no gana a una edición hecha a la vez en otro dispositivo.
  - Las reglas de conflicto son una función pura del estado en `<funcionalidad>_domain` (`ItemTrackerResolver`, `ShoppingListResolver`). Las resoluciones provisionales se calculan, no se escriben, así que todos los dispositivos llegan al mismo resultado. Los ids de conflicto son deterministas.
  - El participante (`<Funcionalidad>SyncParticipant`) vive en el `_domain` y lo registra `<funcionalidad>_isar` en el scope raíz: sigue recibiendo cambios con el plugin desactivado.
  - Un repositorio en memoria se sincroniza si recibe `hlcClock:` y `changeLog:`.
  - Un tipo de conflicto nuevo necesita sus textos en la bandeja de la app (`apps/app/lib/sync/conflict_description.dart` y `app.sync.conflicts` en sus JSON).
- **Nativo:** Android con `INTERNET`, `ACCESS_NETWORK_STATE`, `CHANGE_WIFI_MULTICAST_STATE` y `allowBackup="false"`: una copia restaurada traería una clave que el Keystore de otro teléfono no descifra y la identidad de este dispositivo. iOS con `NSLocalNetworkUsageDescription` y `NSBonjourServices` (`_hometasks._tcp`). En el emulador de Android solo se ve a sí mismo: la red se prueba con teléfonos.
- **Tests:**
  - El motor, con `SyncSimulator` (semillas reproducibles). `SimulatedDevice.advertise()` acepta sesiones: no combinarlo con `controller.start()`, que también acepta.
  - La app, con `SyncedDevice` (`apps/app/test/helpers/synced_device.dart`): varios dispositivos con dobles en memoria en un `InMemorySyncNetwork`. Uno se pinta con `harness.pump` y los demás corren sin UI (`startHeadless`).

## Varios hogares (espacios de datos)
- **Diseño:** §10.4.10 de la spec. Un espacio es una base Isar propia, local o de un hogar (como mucho uno por hogar). Solo se sincroniza el activo.
- **Paquetes:** `core_spaces` (contratos `DataSpaceDirectory` y `DataSpaceStorage`, `deleteOrphanDatabases`; en `testing.dart`, sus tests de contrato y dobles en memoria), `spaces_shared_preferences` (la lista) e `IsarSpaceStorage` en `storage_isar` (las bases).
- **Por espacio / por dispositivo:** los datos, la sincronización y los plugins activos son de cada espacio. La lista de espacios y los accesos rápidos son del dispositivo: van en `deviceAdapters`, en un `ServiceLocator` propio (`DeviceEnvironment`) que no se vacía al cambiar de espacio.
- **App (`apps/app/lib/spaces/`):** `bootstrapSpaces` elige el activo (en el primer arranque, uno sobre la base `default`, sin copiar datos) y borra las bases huérfanas. `SpaceSwitcher` cambia de espacio (libera el entorno, abre el otro, `setActive` solo si abrió; si no, vuelve al anterior). `SpaceRoot` reconstruye `HomeUtilityApp` con `ObjectKey(environment)`. `SpaceHouseholdTracker` anota en la lista el hogar de cada espacio.
- **Clave del hogar:** `HouseholdService.secretKeyFor(householdId)`. La antigua (`legacySecretKey`) no se borra mientras sea la del hogar actual.
- **Tests:** `SpacePhone` (`apps/app/test/helpers/space_phone.dart`): Isar real en una carpeta temporal y el arranque real, con tests normales (no `testWidgets`). Isar comparte instancias por nombre en todo el proceso: dos teléfonos de un test no pueden abrir a la vez una base con el mismo nombre (p. ej. `default`); al segundo se le da antes un espacio propio.

## Trampas de la sincronización en tests
- **Liberar dentro del test:** en `testWidgets`, liberar los dispositivos sincronizados al final del cuerpo, después de `tester.pumpWidget(const SizedBox())`, no en `tearDown` ni en `addTearDown`. Ahí, con la app aún montada, `SyncController.stop()` no termina con el reloj simulado y el test se cuelga. Ver `syncTest` en `apps/app/test/sync_test.dart`.
- **`--timeout` no corta un `testWidgets` colgado:** con el reloj simulado, el límite por test no salta. Para encontrar el que se cuelga, ejecutar el archivo con `--reporter expanded` y ver cuál no termina.
- **Snackbars entre rutas:** con varias pantallas apiladas, `find.text` de un snackbar puede encontrar más de uno. Para comprobar que se avisó una sola vez, mirar el estado del cubit (p. ej. `JoinState.attempt`).

