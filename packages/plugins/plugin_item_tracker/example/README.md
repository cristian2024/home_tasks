# item_tracker_example

App anfitriona mínima para probar el plugin `item_tracker` en un dispositivo real. Arranca igual que lo hará `apps/app` en la Fase 4:
1. Registra en `core_di` los servicios base: `Isar`, `EventBus`, `IdGenerator` y `Clock`.
2. Abre la base de datos con `LocalDatabase.open(contributors: [plugin])`.
3. Aplica el idioma del dispositivo.
4. Llama a `plugin.initialize()`.

## Ejecutar

```bash
cd packages/plugins/plugin_item_tracker/example
flutter run
flutter test     # widget test con hardware falso y repositorio en memoria
```

La configuración nativa (permisos, minSdk 24 y compileSdk 37, entitlements NFC) es la misma que la de `core_hardware/example`; consulta su README. En iOS, `isar_community_flutter_libs` todavía usa CocoaPods, así que Flutter genera un `Podfile` solo para él.

## Recorrido de los criterios de aceptación

1. Pulsa **Cargar datos de ejemplo**: se crean «Caja A» (QR `QR-123`), «Cama» (QR `QR-BED`) y la caja de ropa de invierno (código de barras `049000000443`, con metadatos).
2. Genera códigos QR con esos textos, o escríbelos en el modo **Código** de la pantalla de escaneo.

| Criterio | Pasos | Resultado esperado |
|---|---|---|
| AC-03 | Escanear `QR-123` | Se abre el detalle de «Caja A» |
| AC-04 | Escanear `UNKNOWN-99` | Pantalla «Identificador no registrado» con Crear y Asociar |
| AC-05 | Modo NFC → leer una etiqueta nueva → Asociar → «Cama» | El detalle de «Cama» muestra el QR y la etiqueta NFC; leer cualquiera de los dos abre «Cama» |
| AC-06 | Modo NFC en un dispositivo sin NFC (o con NFC apagado) | Mensaje explicativo con alternativas, sin crash |
| Código manual | Selector **Código** | La cámara se apaga y se oculta; al volver a **Cámara** desaparece el campo |
| Idioma | Selector ES/EN | Todo el plugin cambia de idioma |
