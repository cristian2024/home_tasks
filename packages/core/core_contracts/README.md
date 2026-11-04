# core_contracts

Contratos del sistema de plugins: qué es un plugin, cómo se registra, qué prefiere el usuario y en qué estado está cada uno.

## Contenido

- **`HomePlugin`**: lo que implementa cada plugin.
  - Identidad: `id`, `nameKey` y `descriptionKey` (claves i18n), `icon`, `version`.
  - Ciclo de vida: `isAvailable()`, `initialize()` y `dispose()`.
  - Lo que aporta: sus rutas (`routes`, de `go_router`) y su tarjeta de inicio (`buildDashboardTile`).
- **`HomePluginEntryRoute`** (opcional): la ruta de la pantalla principal (`entryRoute`). Con ella, la grilla del inicio abre el plugin directamente en lugar de mostrar su tarjeta.
- **`PluginRegistry`**: registro de los plugins en tiempo de compilación. Rechaza IDs duplicados.
- **`UserPluginPreference`** (activado y orden) y **`PluginPreferenceRepository`**: dónde se guarda. Cada motor de base de datos lo implementa en su adaptador.
- **`PluginLifecycleManager`**: aplica el ciclo Existencia → Disponibilidad → Activación → Inicialización.
  - `load()` devuelve un `PluginState` por plugin (`PluginStatus`: `unavailable`, `disabled`, `failed` o `ready`).
  - `setEnabled()` y `reorder()` guardan las preferencias.
  - Un plugin que falla nunca bloquea a los demás.

## Uso

La app registra sus plugins en un `PluginRegistry` y deja que `PluginLifecycleManager` los inicialice según las preferencias del usuario. Desactivar un plugin llama a su `dispose()` sin tocar sus datos.

## Tests

`package:core_contracts/testing.dart` trae la batería `pluginPreferenceRepositoryContract`, que toda implementación de `PluginPreferenceRepository` debe pasar, e `InMemoryPluginPreferenceRepository`.

```sh
flutter test
```
