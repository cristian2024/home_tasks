# core_di

Inyección de dependencias del monorepo: un envoltorio fino sobre `get_it`, para que ningún paquete dependa de él directamente.

## Contenido

- **`ServiceLocator`**:
  - Registro: `registerSingleton`, `registerLazySingleton` y `registerFactory`, este último con una instancia nueva en cada `get`. Los registros aceptan `dispose`.
  - Consulta: `get<T>()` e `isRegistered<T>()`.
  - Scopes: `pushScope(name, init:)`, `dropScope(name)` y `hasScope(name)`.
  - `reset()` borra todo; pensado para los tests.
  - `ServiceLocator.instance` es la instancia global de la app.
- **`DependencyModule`**: un paquete que registra sus implementaciones (`register(services)`), p. ej. un adaptador de base de datos o de hardware.

## Uso

- **Quien compone** (la app o un ejemplo) solo elige una lista de `DependencyModule`. Cada uno abre sus recursos y registra sus contratos.
- **Cada plugin** registra sus dependencias en un scope con su ID durante `initialize()` y lo libera en `dispose()`:

```dart
await locator.pushScope('item_tracker', init: (ServiceLocator scope) {
  scope.registerSingleton(ItemTrackerDependencies(...));
});
// ...
await locator.dropScope('item_tracker'); // ejecuta los dispose de sus registros
```

Los registros de un scope ocultan los de scopes anteriores con el mismo tipo.

## Tests

```sh
dart test
```
