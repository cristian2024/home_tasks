# core_events

Comunicación entre plugins por eventos, sin acoplarlos: un plugin publica un hecho («se compró un item») y los que estén escuchando reaccionan. Dart puro.

## Contenido

- `CrossPluginEvent`: base de todo evento. Lleva `emittedAt` (UTC). Quien publica lo pasa siempre desde su `Clock` (`core_utils`), para que los tests puedan fijarlo; si falta, se usa la hora actual.
- `EventBus`: `publish`, `on<T>()` (stream de los eventos de ese tipo) y `dispose`. `EventBus()` crea la implementación por defecto, `StreamEventBus`, en memoria.
- `EventSubscriptions`: junta las suscripciones de un plugin para cancelarlas todas (`cancelAll`) al liberar su scope.

## Uso

La app registra un único `EventBus` en el scope raíz del `ServiceLocator`. Cada plugin:

- **publica** los eventos que define su contrato (`packages/contracts/<funcionalidad>_contract`), no este paquete:

  ```dart
  eventBus.publish(ShoppingItemPurchased(itemId: id, itemName: name, purchasedAt: clock.nowUtc()));
  ```

- **escucha** con un `EventSubscriptions` registrado en su propio scope, para que se cancele con su `dispose()`:

  ```dart
  locator.registerSingleton(
    EventSubscriptions()..listen<ShoppingItemPurchased>(eventBus, onPurchased),
    dispose: (EventSubscriptions s) => s.cancelAll(),
  );
  ```

Los eventos no se guardan: lo publicado mientras un plugin está desactivado se pierde. Para el estado actual se usan capacidades (interfaces del contrato registradas en el locator), no eventos.

## Tests

`package:core_events/testing.dart` trae la batería de contrato `eventBusContract`, que toda implementación de `EventBus` debe pasar, y `RecordingEventBus`, que guarda lo publicado para comprobarlo.

```sh
dart test
```
