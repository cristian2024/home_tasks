# Changelog

## 0.1.0 - 2026-10-27

### Añadido

- Primer adaptador de almacenamiento, sobre Isar (`isar_community` 3.3.2), en `packages/adapters/`. Reemplazará a la parte Isar de `core_storage`.
- `IsarDatabase.open` abre la base con los esquemas de infraestructura y los de cada `IsarSchemaModule` (uno por adaptador Isar de plugin). Falla si dos colecciones distintas tienen el mismo nombre.
- `IsarPluginPreferenceRepository`: `PluginPreferenceRepository` sobre Isar. Pasa `pluginPreferenceRepositoryContract`. Usa la misma colección que `core_storage`, así que las preferencias ya guardadas se siguen leyendo.
- Reexporta la API de Isar para que todos los adaptadores Isar usen la misma versión.
