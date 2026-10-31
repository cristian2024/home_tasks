# Changelog

## 0.1.0 - 2026-10-31

### Añadido

- `SharedPreferencesDataSpaceDirectory`: `DataSpaceDirectory` en `shared_preferences`. Guarda la lista de espacios y el activo en una sola clave (cada cambio es atómico) y aplica los cambios de uno en uno. Una lista guardada ilegible falla con `StateError` en vez de leerse vacía. Pasa `dataSpaceDirectoryContract`.
- `SharedPreferencesSpaces`: `DependencyModule` que lo registra como `DataSpaceDirectory`.
