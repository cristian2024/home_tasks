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

Cobertura: 100 %.
