# core_hardware

Contratos de hardware para identificar objetos: cámara (QR y códigos de barras), NFC y permisos. No importa ningún SDK nativo: las implementaciones están en los adaptadores de `packages/adapters/`.

| Contrato | Adaptador |
| :--- | :--- |
| `CameraIdentifierScanner` | `hardware_mobile_scanner` |
| `NfcIdentifierScanner` | `hardware_nfc_manager` |
| `HardwarePermissions` | `hardware_permission_handler` |

## Contenido

- `IdentifierScanner`: `checkHardware()`, `startScanning()`, `stopScanning()`, `scanStream` y `dispose()`.
  - `CameraIdentifierScanner` añade `buildPreview()`, la vista de la cámara, sin que la pantalla importe el SDK.
  - `NfcIdentifierScanner` añade `writeTag()`.
- `PhysicalScanResult` (valor, `ScanType` y momento), `HardwareStatus` y `ScanException` con su `ScanErrorCode`.
- `HardwarePermissions`: consultar y pedir el permiso de cámara y abrir los ajustes.
- `ScannedValueSanitizer`: limpia el valor leído (caracteres de control, longitud). Lo usan los adaptadores.

## Uso

Quien compone la app elige los adaptadores, y estos registran los contratos en el `ServiceLocator`. Los escáneres son factorías: cada `get` devuelve uno nuevo, que la pantalla libera con `dispose()` al salir. La presentación y el dominio solo importan este paquete. La regla 4 del verificador impide importar `mobile_scanner`, `nfc_manager*` o `permission_handler` fuera de los adaptadores.

## Tests

`package:core_hardware/testing.dart` trae los dobles para los tests de quien consume los contratos: `FakeCameraScanner`, `FakeNfcScanner` y `FakeHardwarePermissions`. Permiten emitir lecturas y errores, simular el estado del hardware y del permiso, y comprobar que el escáner se liberó.

## App de ejemplo

`example/` prueba los adaptadores en un dispositivo real y documenta la configuración nativa (Android e iOS). Consulta su README.
