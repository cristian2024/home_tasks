# core_spaces

Contratos de los espacios de datos, en Dart puro. Un espacio es un conjunto de datos con su propia base: local (sin hogar) o el de un hogar de sincronización. El dispositivo puede tener varios y usa uno, el activo; los datos de uno nunca se mezclan con los de otro.

## Contenido

- **`DataSpace`**: `id`, `name`, `databaseName` (no cambia nunca), `createdAt` (UTC) y `householdId` (`null` si es local). `DataSpace.create` usa la base `space_<id>`.
- **`DataSpaceDirectory`**: la lista de espacios del dispositivo y cuál es el activo. Se guarda fuera de las bases, porque hay que leerla antes de abrir ninguna.
  - `spaces()` y `watchSpaces()`, ordenados por `createdAt` e `id`.
  - `active()` y `setActive(id)`. El primer espacio que se guarda es el activo.
  - `save(space)`: como mucho un espacio por hogar (`DuplicateHouseholdSpaceException`) y una base por espacio (`DuplicateDatabaseNameException`).
  - `remove(id)`: no se puede quitar el activo (`ActiveDataSpaceRemovalException`).
- **`DataSpaceStorage`**: `databaseNames()` y `delete(databaseName)`. Una base abierta no se borra (`DataSpaceInUseException`): borrarla la corrompería.
- **`deleteOrphanDatabases`**: borra las bases `space_*` que no están en la lista. Nunca toca otras bases (p. ej. `default`, la de antes de los espacios) ni las abiertas.

## Uso

Para borrar un espacio, primero se quita de la lista y después se borran sus datos. Si el proceso muere entre medias, `deleteOrphanDatabases` termina el trabajo en el siguiente arranque:

```dart
await directory.remove(space.id);
await storage.delete(space.databaseName);
```

## Tests

`package:core_spaces/testing.dart` trae los tests de contrato `dataSpaceDirectoryContract` y `dataSpaceStorageContract` (con `DataSpaceStorageHarness` para crear, abrir y cerrar bases), que toda implementación debe pasar, e `InMemoryDataSpaceDirectory` e `InMemoryDataSpaceStorage`.

```sh
dart test
```
