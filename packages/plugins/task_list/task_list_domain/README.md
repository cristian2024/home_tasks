# task_list_domain

Dominio de la lista de tareas en Dart puro. No depende de Flutter ni de ningún motor de base de datos.

## Contenido

- **Entidades:**
  - `HouseholdTask`: título, urgencia, estado, categorías, fecha límite o recurrencia (se excluyen) y última vez que se hizo.
  - `TaskCategory`, alias de `ListCategory` (paquete `categories`, que se reexporta), con `DefaultTaskCategory` para las que se crean por defecto.
- **Estado (`HouseholdTask.stateAt`):** atrasada, hoy, próxima, sin fecha, en espera (repetida cuya ventana no se ha abierto) o hecha. La fecha límite es un día de calendario (`CalendarDay`, de `core_utils`) y se compara con el día local, no con la hora UTC. Una tarea repetida nunca queda hecha: vuelve a esperar su ventana.
- **`TaskListView`:** une cada tarea con su estado y sus categorías (`entries`), las ordena (`compare`: urgencia, fecha y título), las agrupa (`group`) por fecha (Atrasadas, Hoy, Próximas y Sin fecha) o por categoría, lista las hechas (`done`) y resume la tarjeta del inicio (`summary`).
- **`TaskListFilter`:** por categorías, urgencias y estados (`filterableStates`: atrasada, en espera y sin fecha).
- **`TaskValidator`:** título obligatorio de hasta 100 caracteres y nombre de categoría.
- **Errores:** `sealed TaskListException` (`TaskNotFoundException`, `TaskCategoryNameTakenException`…).
- **`TaskListRepository`:** el contrato del repositorio. Los borrados son lógicos.
- **Sincronización:** `TaskListCodec`, `TaskListResolver` (gana el último cambio por campo y un borrado gana a una edición; por ahora sin conflictos), `TaskListSyncStore` y `TaskListSyncParticipant`.

## Testing

`package:task_list_domain/testing.dart` trae:

- `InMemoryTaskListRepository`, que se sincroniza si recibe `hlcClock` y `changeLog`.
- `taskListRepositoryContract`: los tests de contrato que debe pasar toda implementación del repositorio.
- `taskListSyncContract`: los de sincronización, con `taskListSyncRecords` (cambios de tres dispositivos).

## Tests

```sh
dart test
```
