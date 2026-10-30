# core_utils

Utilidades neutrales en Dart puro para generar IDs y leer la hora sin depender del sistema. Todos los paquetes las inyectan en lugar de llamar a `Uuid()` o a `DateTime.now()`, para que los tests sean deterministas.

## Contenido

| Contrato | Implementación | En tests |
| :--- | :--- | :--- |
| `IdGenerator` (`newId()`) | `UuidV4Generator`: UUID v4, obligatorio para las entidades de dominio | un generador propio, p. ej. secuencial (`id-1`, `id-2`…) |
| `Clock` (`nowUtc()`) | `SystemClock`: la hora actual en UTC | `FixedClock`: hora fija, que avanza con `advance(duration)` |

Además, `isUuidV4(value)` comprueba que un texto es un UUID v4 canónico (minúsculas).

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
