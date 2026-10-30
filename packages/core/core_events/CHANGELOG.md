# Changelog

## 0.1.2 - 2026-10-29

### Añadido

- README del paquete.

### Cambiado

- La documentación de `CrossPluginEvent` pide pasar siempre `emittedAt` desde el `Clock` de quien publica. Sin él se sigue usando la hora actual.

## 0.1.1 - 2026-10-28

### Añadido

- `EventBus` es ahora un contrato. `EventBus()` sigue creando la implementación por defecto, `StreamEventBus`, así que el código existente no cambia.
- `EventSubscriptions`: junta las suscripciones de un plugin para cancelarlas todas al descartar su scope (`cancelAll`, sin esperar a que terminen).
- `CrossPluginEvent` acepta `emittedAt` (p. ej. del `Clock` de quien publica) y lo guarda en UTC. Sin él usa la hora actual, como antes.
- `package:core_events/testing.dart`: batería de contrato `eventBusContract` y `RecordingEventBus`, que guarda lo publicado para comprobarlo en los tests.

### Interno

- `StreamEventBus` usa un `StreamController` broadcast en lugar de rxdart, que deja de ser dependencia.
- Tipos explícitos en los tests (`always_specify_types`).

## 0.1.0 - 2026-10-21

Primera versión con CHANGELOG. Incluye lo hecho hasta esa fecha:

### Añadido

- `EventBus` para publicar y escuchar eventos tipados entre plugins (`publish`, `on<T>()`, `dispose`).
- `CrossPluginEvent` con `emittedAt` en UTC, y el evento `ItemCreatedCrossEvent`.
