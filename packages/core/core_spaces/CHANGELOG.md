# Changelog

## 0.1.0 - 2026-10-31

### Añadido

- `DataSpace`: un conjunto de datos con su propia base, local o de un hogar (`householdId`). `DataSpace.create` usa la base `space_<id>`.
- `DataSpaceDirectory`: los espacios del dispositivo y el activo. El primero que se guarda es el activo; como mucho un espacio por hogar y una base por espacio; no se puede quitar el activo.
- `DataSpaceStorage`: lista y borra las bases de los espacios; una base abierta no se borra.
- `deleteOrphanDatabases`: borra las bases `space_*` que ya no están en la lista (p. ej. tras un borrado interrumpido).
- `DataSpaceException` (`sealed`) con sus casos, y `checkCanSaveSpace` y `sortSpaces` para las implementaciones.
- `package:core_spaces/testing.dart`: tests de contrato `dataSpaceDirectoryContract` y `dataSpaceStorageContract`, e `InMemoryDataSpaceDirectory` e `InMemoryDataSpaceStorage`.
