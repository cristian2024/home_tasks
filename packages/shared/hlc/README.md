# hlc

Reloj lógico híbrido (HLC): marcas de tiempo con un orden total entre dispositivos, aunque sus relojes no estén sincronizados. La sincronización lo usa para decidir qué cambio de un campo es el último (§10.4 de la spec). Dart puro.

## Contenido

- **`Hlc`**: `wallTime` (milisegundos UTC), `counter` y `deviceId`.
  - El orden es por tiempo de pared, después por contador y, como desempate final, por `deviceId`. Implementa `Comparable` y tiene `isBefore` e `isAfter`.
  - Igualdad por valor (`Equatable`).
  - `encode()` lo escribe como texto de ancho fijo (`001761827400000-00042-<deviceId>`), que ordenado como texto da el mismo orden. `Hlc.parse` lo lee.
  - `Hlc.fromDateTime(time, deviceId:)` crea una marca a partir de un instante, p. ej. el `updatedAt` de un dato anterior a la sincronización.
- **`HlcClock`**: el reloj de un dispositivo, sobre el `Clock` de `core_utils`. Cada marca que genera es mayor que todas las anteriores.
  - `now()`: marca para un cambio local.
  - `receive(remote)`: avanza con una marca de otro dispositivo y devuelve una local mayor que ella.
  - `last`: la última marca. Quien lo usa la guarda y la pasa al crearlo de nuevo (`last:`), para que el orden se mantenga entre reinicios aunque el reloj del sistema retroceda.
- **Errores** (`sealed HlcException`):
  - `HlcClockDriftException`: una marca recibida va por delante del reloj del sistema más de `maxDrift` (5 minutos por defecto). El reloj no la adopta.
  - `HlcCounterOverflowException`: más de 65 535 marcas en el mismo milisegundo.

## Uso

```dart
final HlcClock hlcClock = HlcClock(deviceId: deviceId, clock: const SystemClock(), last: savedHlc);

final Hlc stamp = hlcClock.now();
final Hlc afterRemote = hlcClock.receive(Hlc.parse(remoteStamp));
```

## Tests

```sh
dart test
```

Cobertura: 100 %.
