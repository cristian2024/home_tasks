# Changelog

## 0.1.0 - 2026-10-30

### Añadido

- `Hlc`: marca de un reloj lógico híbrido (tiempo de pared en milisegundos UTC, contador y `deviceId`) con orden total, igualdad por valor y texto ordenable (`encode` y `Hlc.parse`). `Hlc.fromDateTime` la crea desde un instante.
- `HlcClock`: reloj de un dispositivo sobre el `Clock` de `core_utils`, con `now()` para cambios locales, `receive(remote)` para marcas recibidas y `last` para continuar tras un reinicio.
- Errores `HlcClockDriftException` (marca recibida demasiado adelantada, `maxDrift`) y `HlcCounterOverflowException` (contador agotado), bajo el `sealed` `HlcException`.
- README del paquete.
