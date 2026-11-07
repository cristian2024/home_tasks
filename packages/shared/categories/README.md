# categories

Categorías de una lista de la casa (compras, tareas), en Dart puro. Cada funcionalidad guarda las suyas: este paquete solo comparte la forma y las reglas, para que se comporten igual.

## Contenido

- `ListCategory`: `id`, `name` (lo que escribió el usuario), `defaultKey` (las que la lista crea la primera vez y se traducen por su clave) y `sortOrder`.
- `ListCategories`:
  - `maxNameLength` (40) y `problemWith(name)`: nombre vacío o demasiado largo.
  - `normalize(name)` e `isNameTaken(categories, name, nameOf: …)`: dos categorías no pueden llamarse igual, sin distinguir mayúsculas.
  - `sorted`, `nextSortOrder` y `reordered`: el orden de la lista.

## Uso

Cada funcionalidad declara su tipo como alias, para no repetir la entidad:

```dart
typedef TaskCategory = ListCategory;
```

No tiene textos: los nombres de las categorías por defecto los traduce quien las muestra.

## Tests

```sh
dart test
```
