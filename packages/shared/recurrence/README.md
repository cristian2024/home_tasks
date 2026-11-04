# recurrence

Recurrencia aproximada de algo que se repite (una compra, una tarea): cada entre `minDays` y `maxDays` días desde la última vez. Dart puro.

## Contenido

- **`Recurrence.between(minDays, maxDays)`**: exige `1 <= minDays <= maxDays <= 365`. `Recurrence.fixed(days)` crea una de días exactos (`isFixed`).
- **`windowAfter(lastDone)`**: devuelve la `RecurrenceWindow` siguiente. Se abre a los `minDays` días y se cierra al terminar el día `maxDays`, que cuenta entero. Todo en UTC.
- **`statusAt(now, lastDone:)`** devuelve un `RecurrenceStatus`:
  - `waiting`: la ventana aún no se abre;
  - `due`: está abierta;
  - `overdue`: ya se cerró.

  Si nunca se hizo (`lastDone` es `null`), es `due`.

## Uso

```dart
final Recurrence eggs = Recurrence.between(8, 15);
final RecurrenceStatus status = eggs.statusAt(clock.nowUtc(), lastDone: lastPurchase);
```

Cada funcionalidad guarda `minDays`, `maxDays` y la última vez, y decide qué hacer con el estado. La lista de compras, por ejemplo, vuelve a mostrar el item cuando es `due`.

## Tests

```sh
dart test
```

Cobertura: 100 %.
