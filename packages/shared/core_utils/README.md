# core_utils

Utilidades neutrales en Dart puro para generar IDs y leer la hora sin depender del sistema. Todos los paquetes las inyectan en lugar de llamar a `Uuid()` o a `DateTime.now()`, para que los tests sean deterministas.

## Contenido

| Contrato | Implementación | En tests |
| :--- | :--- | :--- |
| `IdGenerator` (`newId()`) | `UuidV4Generator`: UUID v4, obligatorio para las entidades de dominio | un generador propio, p. ej. secuencial (`id-1`, `id-2`…) |
| `Clock` (`nowUtc()`) | `SystemClock`: la hora actual en UTC | `FixedClock`: hora fija, que avanza con `advance(duration)` |

Además, `isUuidV4(value)` comprueba que un texto es un UUID v4 canónico (minúsculas).

**Días de calendario.** Una fecha sin hora (p. ej. una fecha límite) se guarda como la medianoche UTC de ese día: `CalendarDay.of(date)`. Para compararla con la hora actual se usa el día local, `clock.today()`, y no `nowUtc()`: a las 23:00 en Bogotá ya es el día siguiente en UTC. `CalendarDay.relativeTo(day, today: …)` dice si es ayer, hoy, mañana u otro día; los textos los pone quien lo muestra.

## Uso

La app registra `UuidV4Generator` y `SystemClock` en el `ServiceLocator`. Los plugins los piden al iniciar y los pasan a sus casos de uso:

```dart
final Clock clock = locator.isRegistered<Clock>() ? locator.get<Clock>() : const SystemClock();
final DateTime now = clock.nowUtc(); // siempre UTC
```

## Tests

```sh
dart test
```
