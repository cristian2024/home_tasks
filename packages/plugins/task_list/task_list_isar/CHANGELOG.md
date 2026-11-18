# Changelog

## 0.1.1 - 2026-11-18

### Interno

- Los tests preparan `libisar` con `initializeIsarForTests()` de `storage_isar`, que la descarga de un test en uno. Antes, dos archivos de test podían descargarla a la vez y uno la cargaba a medio escribir (SIGBUS en la CI).

## 0.1.0 - 2026-11-07

### Añadido

- Primera versión: `TaskListIsar` con el repositorio Isar de la lista de tareas, su sincronización y la migración de lo guardado antes de componerla.
