# plugin_item_tracker

Plugin de identificación y seguimiento de objetos de la casa (ID `item_tracker`, rutas bajo `/item-tracker`). Implementa `HomePlugin` de `core_contracts`.

## Qué hace

- **Escanear** un QR, un código de barras o una etiqueta NFC, o escribir el código a mano. Un código conocido abre el objeto; uno desconocido ofrece crear un objeto nuevo o asociarlo a uno existente.
- **Objetos:** crear, editar (nombre, descripción, metadatos) y añadir notas al historial. Las acciones técnicas (crear, editar, mover…) quedan registradas en el historial.
- **Identificadores:** asociar varios a un objeto y quitarlos. Un identificador quitado queda libre para otro objeto.
- **Contenedores:** meter un objeto dentro de otro (máximo 5 niveles, configurable con `--dart-define=ITEM_TRACKER_MAX_DEPTH=n`), moverlo o sacarlo.
- **Borrar un objeto** desde su detalle. Si contiene otros, se elige entre pasarlos a su contenedor o borrar todo.
- Tarjeta de inicio con el número de objetos y acceso a escanear y al listado.

## Integración

Quien compone la app:

1. Elige el adaptador de almacenamiento, p. ej. `ItemTrackerIsar` de `item_tracker_isar` dentro de `IsarStorage`. El plugin pide `HouseholdItemRepository` al `ServiceLocator` y nunca importa su adaptador.
2. Registra el plugin con `ItemTrackerPlugin(locator: locator)`. `EventBus`, `IdGenerator` y `Clock` son opcionales: si faltan en el locator, usa los suyos.
3. Inyecta los textos del plugin desde sus archivos (`assets/i18n/item_tracker/<idioma>.json`). Los de `lib/src/i18n/` son el contrato y el respaldo.

El plugin registra sus dependencias en el scope `item_tracker` y lo libera en `dispose()`.

## Tests

- Casos de uso al 100 % (`test/domain/`).
- `PluginHarness` (`test/helpers/presentation_fixtures.dart`) monta el plugin real con hardware falso (`package:core_hardware/testing.dart`) y repositorio en memoria.

## App de ejemplo

`example/` prueba el plugin en un dispositivo real. Consulta su README.
