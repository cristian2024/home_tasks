# item_tracker_domain

Dominio de la funcionalidad de seguimiento de objetos, en Dart puro: entidades, reglas de validación y de jerarquía, errores y el contrato del repositorio. No depende de Flutter ni de ningún motor de base de datos.

## Contenido

- **Entidades:**
  - `HouseholdItem`: objeto con nombre, descripción, metadatos y `parentId` si está dentro de otro.
  - `PhysicalIdentifier`: QR, código de barras o NFC ligado a un objeto.
  - `ItemEvent`: entrada del historial. Los eventos técnicos guardan datos, no texto traducido.
- **Reglas:**
  - `ItemValidator` e `ItemMetadata`: límites de los campos y de los metadatos.
  - `ItemTree`: ruta, nivel, contenido, descendientes y altura a partir de la lista de objetos.
  - `ContainmentPolicy`: máximo de niveles de anidamiento (5 por defecto).
- **Errores:** `sealed ItemTrackerException` (`ItemNotFoundException`, `IdentifierAlreadyBoundException`, `ItemContainmentCycleException`…), para tratarlos de forma exhaustiva.
- **Contrato `HouseholdItemRepository`:** las operaciones que escriben varias entidades son atómicas. Quitar un identificador y borrar objetos son borrados lógicos: lo borrado deja de aparecer en consultas y streams, y sus identificadores quedan libres.

## Implementar el repositorio

Toda implementación debe pasar la batería de contrato de `package:item_tracker_domain/testing.dart`:

```dart
householdItemRepositoryContract(
  'SQLite',
  create: () => SqliteHouseholdItemRepository(...),
  dispose: (HouseholdItemRepository repository) => ...,
);
```

El mismo archivo trae `InMemoryHouseholdItemRepository`, para los tests y las apps de ejemplo de otros paquetes.

## Sincronización

item_tracker se sincroniza entre dispositivos con `core_sync` (spec §10.4):

- Cada repositorio guarda, aparte de las entidades, su **copia sincronizada** (`SyncedEntity`, de core_sync): el último valor de cada campo y la marca con que se escribió. Las escrituras locales la actualizan y registran sus cambios (`LocalSyncRecorder`) en la misma transacción. Para eso implementa también `ItemTrackerSyncStore`.
- `ItemTrackerSyncParticipant` fusiona los cambios recibidos en las copias y, con `ItemTrackerResolver`, calcula lo que lee la app:

  | Situación | Lo que se ve | Conflicto |
  | :--- | :--- | :--- |
  | Mover algo a un contenedor borrado (o borrarlo a la vez) | Pasa al contenedor del borrado o queda suelto | `containerDeleted` |
  | Movimientos que forman un ciclo o superan los niveles | Se revierte el de mayor marca; queda suelto | `moveReverted` |
  | El mismo identificador en dos objetos | Se queda el asociado antes; el otro, quitado | `identifierBoundTwice` |
  | Identificador de un objeto borrado | Queda quitado | No |

  Es una función pura del estado: todos los dispositivos llegan a lo mismo, en cualquier orden, sin escribir cambios. Las resoluciones elegidas por el usuario (`resolveConflict`) son escrituras normales y se sincronizan.

Un repositorio que se sincroniza debe pasar también `itemTrackerSyncContract`:

```dart
itemTrackerSyncContract('SQLite', create: () => ItemTrackerSyncSubject(
  repository: repository,
  participant: ItemTrackerSyncParticipant(store: repository, repository: repository),
  log: changeLog,
));
```

`InMemoryHouseholdItemRepository(hlcClock: …, changeLog: …)` se sincroniza; sin esos parámetros, no.

Cobertura: 100 %.
