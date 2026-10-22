# CLAUDE.md - Guía de Desarrollo para Claude Code

## Comandos del Monorepo (Melos)
- **Instalación/Bootstrap:** `melos bs`
- **Análisis estático:** `melos run analyze`[cite: 1]
- **Ejecutar pruebas:** `melos run test`[cite: 1]
- **Generar código (Isar / Slang):** `melos run build:g`[cite: 1]

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
   - La lógica de hardware (Cámara/NFC) debe aislarse detrás de las abstracciones de `packages/core/core_hardware`. La capa de presentación o dominio no debe invocar SDKs nativos directamente[cite: 1].

---

## Stack Tecnológico Clave
- **Framework:** Flutter (>=3.27.0) / Dart[cite: 1]
- **Gestión de Estado:** `flutter_bloc` / `Cubit`[cite: 1]
- **Navegación:** `go_router` (enrutamiento declarativo)[cite: 1]
- **Base de Datos Local:** `isar` (vía repositorios abstractos)[cite: 1]
- **Internacionalización:** `slang` (archivos JSON por paquete bajo namespace)[cite: 1]
- **Inyección de Dependencias:** `get_it` (`core_di`)[cite: 1]

---

## Convenciones de Código
- Nombres de archivos y carpetas en **snake_case**[cite: 1].
- Excluir archivos generados (`*.g.dart`, `*.i18n.json`) del linter según `analysis_options.yaml`[cite: 1].
- Todo componente interactivo de UI debe incluir accesibilidad (`Semantics` o `tooltip`)[cite: 1].

---

## Monorepo (Fase 1)
- **Melos 8 + Dart pub workspaces:** no existe `melos.yaml`; la configuración de Melos vive en la sección `melos:` del `pubspec.yaml` raíz. Cada paquete nuevo declara `resolution: workspace` y debe quedar cubierto por la lista `workspace:` de la raíz.
- Si `melos` falla con "Invalid kernel binary format": `dart pub global activate melos`.
- **Verificación completa antes de dar algo por terminado:** `melos run verify` (analyze + verify:arch + test).
- **Reglas de importación (§5.2):** `melos run verify:arch` ejecuta `tool/verify_architecture.dart` (lógica en `tool/src/`, tests en `tool/test/`).
- **Plugins:** implementan `HomePlugin` (`core_contracts`), incluido `isAvailable()`. El ciclo de vida lo aplica `PluginLifecycleManager`; las preferencias se persisten vía `PluginPreferenceRepository`.
- **DI:** usar `ServiceLocator` de `core_di`, nunca `get_it` directamente. Cada plugin registra sus dependencias en un scope con su ID (`pushScope`) y lo libera en `dispose()` (`dropScope`).
- **Igualdad por valor:** extender `Equatable` (paquete `equatable`) y declarar `props`; nunca sobrescribir `operator ==`/`hashCode` a mano. Aplica a entidades, value objects y estados de BLoC/Cubit.

## Fase 2 (persistencia y hardware)
- **Isar:** usar `isar_community` fijado en 3.3.2 (nunca `isar`). Las capas data importan Isar a través de `package:core_storage/core_storage.dart`, que la reexporta. Un plugin con colecciones implementa `StorageSchemaContributor`; la app abre la base con `LocalDatabase.open(contributors: ...)` incluyendo a **todos** los plugins registrados, también los desactivados.
- **Tests con Isar:** `setUpAll(() => Isar.initializeIsarCore(download: true))`. Descarga `libisar.dylib` en el paquete (está en `.gitignore`).
- **Hardware:** la presentación usa solo `CameraIdentifierScanner`, `NfcIdentifierScanner` y `HardwarePermissions`. La cámara se muestra con `buildPreview()`. En tests usar los fakes de `package:core_hardware/testing.dart`.
- **Regla 4 del verificador:** solo `core_hardware` puede importar `mobile_scanner`, `nfc_manager*` o `permission_handler`.
- **IDs y tiempo:** inyectar `IdGenerator` (`UuidV4Generator`) y `Clock` (`SystemClock`, `FixedClock` en tests) de `core_utils` en lugar de llamar a `Uuid()` o `DateTime.now()` en dominio y data.
- **ID del plugin de objetos:** `item_tracker` (scope DI, preferencia y namespace i18n); su ruta base es `/item-tracker`.
- **App de ejemplo de hardware:** `packages/core/core_hardware/example`. Sirve de referencia para la configuración nativa de `apps/app`: Android minSdk 24 y compileSdk 37; en iOS, `Info.plist` y `Runner.entitlements`. Los plugins de iOS usan Swift Package Manager: **no** escribir un Podfile a mano. Si un plugin no admite SPM (p. ej. `isar_community_flutter_libs`), Flutter genera el Podfile solo para él y se versionan `Podfile` y `Podfile.lock`.
- **Widget tests con streams:** después de emitir desde un fake, usar `await tester.pumpAndSettle()`. Con un solo `pump()` el evento llega después del frame.

## Fase 3 (UI base y plugin item_tracker)
- **i18n:** cada paquete tiene `slang.yaml` y `lib/src/i18n/{es,en}.i18n.json`. Se regenera con `dart run slang` en el paquete (no con build_runner). Con `lazy: false` y `enum_name`/`class_name`/`translate_var` propios del paquete. Registrar el paquete en `LocalizationCoordinator.instance` y usar `commonStrings.common.*` para textos comunes.
- **UI:** usar los componentes de `design_system` (`AppButton`, `AppIconButton` con tooltip, `AppTextField`, `AppStatusView`…) en lugar de los widgets Material sueltos.
- **Plugin item_tracker:** las reglas de negocio están en el §9.4 de la spec (validación, rechazo de identificadores ya asociados, eventos técnicos automáticos). Los errores de dominio son el `sealed` `ItemTrackerException`.
- **Isar nativo:** una violación de índice único llega como `IsarError` con "Unique index violated", no como `IsarUniqueViolationError` (ese es solo para web).
- **mocktail:** `captureAny` captura los argumentos con nombre en orden alfabético.
- **Cobertura:** casos de uso y mappers deben quedar al 100 % (`flutter test --coverage`).
- **Plugin item_tracker (presentación):** `ScanBloc` para el escaneo y Cubits para el resto. Las pantallas devuelven resultados con `context.pop(itemId)` (ver §12.1). En los tests de widgets usar `PluginHarness` (`test/helpers/presentation_fixtures.dart`), que monta el plugin real con hardware falso y repositorio en memoria.

## Trampas conocidas en tests
- **Handlers de bloc:** no hacer `await` de `subscription.cancel()` ni de `dispose()` de escáneres dentro de un handler. En `testWidgets` esos futuros no se completan con el reloj simulado y el bloc se queda bloqueado. Lanzarlos con `unawaited`.
- **`blocTest`:** cierra el bloc antes de `verify`. Comprobar dentro de `act` el estado que el cierre cambia (p. ej. escáneres liberados).
- **`tester.pageBack()`:** busca el tooltip en inglés. Con la app en español, usar `tester.tap(find.byType(BackButton))`.
- **`pumpAndSettle`:** nunca termina con indicadores de carga animados visibles. Usar `pump()`.
- **`SnackBar`:** llamar a `hideCurrentSnackBar()` antes de `showSnackBar` para que no se queden en cola.

## Fase 4 (apps/app)
- **Estructura:**
  - `lib/app_module_registrar.dart`: registro de plugins (`appPluginFactories`).
  - `lib/bootstrap.dart`: arranque testeable (`bootstrapApp`).
  - `lib/plugins/plugin_controller.dart`: estado de los plugins para inicio, catálogo y guard.
  - `lib/navigation/`: router y `PluginRouteGuard`.
  - `lib/home/` y `lib/catalog/`.
- **Añadir un plugin:**
  1. Añadir la dependencia en `apps/app/pubspec.yaml`.
  2. Añadir una `PluginFactory` en `appPluginFactories`. La factoría debe registrar las traducciones del plugin (como `registerLocalization()` de item_tracker).
  3. Sus rutas deben ser absolutas y compartir un primer segmento propio (el guard lo usa como prefijo).
- **Idioma:**
  - Envolver con `LanguageRebuilder` (`core_ui`) el contenido de las rutas. El router de la app ya lo hace con `withLanguageRebuild`.
  - Sin eso, las páginas abiertas no cambian de idioma, porque los textos de slang son globales y GoRouter conserva su `Navigator` con una `GlobalKey`.
  - Para traducir claves de otros paquetes: `LocalizationCoordinator.translate(key)`.
- **Tests de la app:**
  - `AppHarness` (`test/helpers/app_harness.dart`): plugin real con hardware falso, repositorios en memoria y `FakeHomePlugin` configurable.
  - AC-02 con Isar real en `test/ac02_persistence_test.dart`.
  - En dispositivo o simulador: `cd apps/app && flutter test integration_test -d <id>`.
- **`HomeUtilityApp`:** crea su router con el primer `AppEnvironment`. Para simular un reinicio en un test, usar `key: ObjectKey(environment)`.
- **CI:** `.github/workflows/ci.yml` ejecuta `melos run verify` en Ubuntu. Si se sube la versión de Flutter o Melos, actualizarla también ahí.
