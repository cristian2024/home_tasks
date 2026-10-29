# Changelog

## 0.1.2 - 2026-10-28

### Añadido

- `HomePluginEntryRoute`: interfaz opcional para un plugin con pantalla principal (`entryRoute`). La app la abre directamente donde no cabe la tarjeta del plugin, como la grilla del inicio. Los plugins que no la implementan no cambian.

### Corregido

- El `onCancel` de `InMemoryPluginPreferenceRepository.watch()` ya no devuelve el futuro de `cancel()`. `watch().first` podía quedarse esperando con el reloj simulado de `testWidgets`.

## 0.1.1 - 2026-10-27

### Añadido

- `pluginPreferenceRepositoryContract` (`package:core_contracts/testing.dart`): tests de contrato que debe pasar toda implementación de `PluginPreferenceRepository`, sea cual sea el motor de base de datos.

### Corregido

- `InMemoryPluginPreferenceRepository.watch()` emite el estado actual al suscribirse, como las implementaciones con base de datos. Antes solo emitía en los cambios posteriores.

### Interno

- Tipos explícitos en todo el paquete (`always_specify_types`).

## 0.1.0 - 2026-10-22

Primera versión con CHANGELOG. Incluye lo hecho hasta esa fecha:

### Añadido

- `HomePlugin`: contrato de un plugin (identidad, disponibilidad, ciclo de vida, rutas y tarjeta del inicio).
- `PluginRegistry` y `PluginLifecycleManager`: registro y ciclo de vida Existencia → Disponibilidad → Activación → Inicialización, con fallos aislados por plugin.
- `PluginPreferenceRepository` y `UserPluginPreference`: activación y orden de cada plugin.
- `InMemoryPluginPreferenceRepository` en `package:core_contracts/testing.dart`.
