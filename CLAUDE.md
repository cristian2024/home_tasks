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
