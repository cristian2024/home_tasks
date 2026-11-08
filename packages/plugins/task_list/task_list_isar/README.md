# task_list_isar

Adaptador Isar de la lista de tareas. Guarda tareas y categorías con borrado lógico, y registra cada escritura para la sincronización en la misma transacción.

## Uso

Quien compone la app solo lo elige, dentro de `IsarStorage`, también si el plugin está desactivado:

```dart
IsarStorage(features: <IsarFeature>[TaskListIsar()])
```

Con la base abierta registra `TaskListRepository` en el `ServiceLocator` y añade su `TaskListSyncParticipant` a `SyncParticipants` en el scope raíz. Si la app no compuso la sincronización, no registra nada en el log; al componerla, migra una vez lo guardado antes.

La fecha límite se guarda como medianoche UTC de su día: Isar la devuelve en hora local y el mapper la lleva de vuelta al mismo día.

## Tests

Pasa los tests de contrato del repositorio y de la sincronización de `task_list_domain`:

```sh
flutter test
```
