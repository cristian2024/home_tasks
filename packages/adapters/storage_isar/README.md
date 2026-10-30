# storage_isar

Adaptador de almacenamiento local sobre Isar ([`isar_community`](https://pub.dev/packages/isar_community) 3.3.2). Abre la base de datos y registra los repositorios en el `ServiceLocator`; la app no ve nada de Isar.

## Uso

Quien compone la app solo lo elige, con los adaptadores Isar de sus funcionalidades:

```dart
IsarStorage(features: <IsarFeature>[ItemTrackerIsar(), ShoppingListIsar()])
```

Al registrarse:
- abre la base (por defecto en la carpeta de documentos de la app; `directory` y `name` la cambian);
- registra `PluginPreferenceRepository` (`core_contracts`) con su implementación Isar;
- llama a cada `IsarFeature` para que registre sus contratos.

La base se cierra con `ServiceLocator.reset()`.

**Isar exige conocer todos los esquemas al abrir la base.** Por eso `features` lleva los adaptadores de **todos** los plugins registrados, también los desactivados, para que sus datos sigan intactos.

## Para los adaptadores de las funcionalidades

Un adaptador Isar (p. ej. `item_tracker_isar`) importa `package:storage_isar/adapter.dart`, que reexporta la API de Isar para que todos usen la misma versión, e implementa `IsarFeature`:
- `schemas`: sus colecciones;
- `register(services, isar)`: registra sus repositorios con la base ya abierta.

Los nombres de colección y de base de datos no cambian entre versiones, para que los datos guardados se sigan leyendo.

## Tests

Usan Isar real. `setUpAll(() => Isar.initializeIsarCore(download: true))` descarga `libisar` en el paquete (está en `.gitignore`).

```sh
flutter test
```

`IsarPluginPreferenceRepository` pasa `pluginPreferenceRepositoryContract`.
