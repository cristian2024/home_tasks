# Changelog

## 0.2.2 - 2026-10-31

### Añadido

- `IsarSpaceStorage`: `DataSpaceStorage` (`core_spaces`) sobre los archivos de Isar. Lista las bases de una carpeta y borra una con su `.lock`; una base abierta no se borra (`DataSpaceInUseException`). `IsarSpaceStorage.documents()` usa la carpeta de `IsarStorage`. Pasa `dataSpaceStorageContract`.

### Interno

- Test de que dos bases con otro nombre (dos espacios) no comparten datos ni preferencias de plugins.

## 0.2.1 - 2026-10-29

### Añadido

- README del paquete.

## 0.2.0 - 2026-10-27

### Añadido

- `IsarStorage`: `DependencyModule` de `core_di`. Quien compone la app solo lo elige (`IsarStorage(features: <IsarFeature>[...])`); al registrarse abre la base de datos (por defecto en la carpeta de documentos de la app) y registra `PluginPreferenceRepository` y los contratos de cada funcionalidad en el `ServiceLocator`. La base se cierra con `ServiceLocator.reset`.
- `IsarFeature`: adaptador Isar de una funcionalidad. Aporta sus colecciones y registra sus implementaciones con la base ya abierta.
- `package:storage_isar/adapter.dart`: para los adaptadores Isar de las funcionalidades. Reexporta la API de Isar e `IsarFeature`.

### Eliminado

- **Incompatible:** `IsarSchemaModule` (sustituido por `IsarFeature`).
- **Incompatible:** `package:storage_isar/storage_isar.dart` ya no exporta `IsarDatabase`, `IsarPluginPreferenceRepository` ni la API de Isar: quien compone la app no necesita nada de Isar.

## 0.1.0 - 2026-10-27

### Añadido

- Primer adaptador de almacenamiento, sobre Isar (`isar_community` 3.3.2), en `packages/adapters/`. Reemplazará a la parte Isar de `core_storage`.
- `IsarDatabase.open` abre la base con los esquemas de infraestructura y los de cada `IsarSchemaModule` (uno por adaptador Isar de plugin). Falla si dos colecciones distintas tienen el mismo nombre.
- `IsarPluginPreferenceRepository`: `PluginPreferenceRepository` sobre Isar. Pasa `pluginPreferenceRepositoryContract`. Usa la misma colección que `core_storage`, así que las preferencias ya guardadas se siguen leyendo.
- Reexporta la API de Isar para que todos los adaptadores Isar usen la misma versión.
