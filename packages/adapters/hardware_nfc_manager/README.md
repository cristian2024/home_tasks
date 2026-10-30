# hardware_nfc_manager

Adaptador de `core_hardware` para NFC: lee y escribe etiquetas con [`nfc_manager`](https://pub.dev/packages/nfc_manager).

## Uso

Quien compone la app solo lo elige:

```dart
adapters: <DependencyModule>[NfcManagerHardware()]
```

`NfcManagerHardware` registra una **factoría** de `NfcIdentifierScanner` en el `ServiceLocator`: cada `get` devuelve un escáner nuevo, que quien lo pide libera con `dispose()`.

## Qué valor devuelve

- El primer registro NDEF Text o URI legible del tag.
- Si no tiene ninguno, su UID en hexadecimal mayúscula (p. ej. `04A20F`).
- El valor pasa por `ScannedValueSanitizer` de `core_hardware`.

`writeTag` escribe un registro Text (UTF-8). En iOS, CoreNFC muestra su propio diálogo. En Android no hay interfaz del sistema, así que la pantalla muestra la suya mientras dura la sesión.

## Configuración nativa

- Android: permiso `NFC` en el `AndroidManifest.xml`.
- iOS: capacidad *Near Field Communication Tag Reading* (`Runner.entitlements`) y `NFCReaderUsageDescription` en `Info.plist`.

Consulta la app de ejemplo de `core_hardware`.

## Tests

```sh
flutter test
```

Prueban el registro en el locator y la codificación NDEF (`NdefCodec`). La lectura real necesita un dispositivo.
