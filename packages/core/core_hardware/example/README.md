# core_hardware_example

App mínima para probar `core_hardware` en un dispositivo real: escaneo de QR y códigos de barras con la cámara, lectura y escritura de tags NFC y el flujo de permisos.

Solo usa los contratos públicos (`CameraIdentifierScanner`, `NfcIdentifierScanner`, `HardwarePermissions`), igual que lo hará la presentación de los plugins. El verificador de arquitectura lo comprueba con la Regla 4.

## Ejecutar

```bash
cd packages/core/core_hardware/example
flutter run            # con un dispositivo conectado
flutter test           # widget tests con los fakes de package:core_hardware/testing.dart
```

## Configuración nativa que necesita cualquier app que use core_hardware

**Android** (`android/app`)
- `minSdk = 24`: lo exige `nfc_manager` 4.x.
- `compileSdk = 37`: lo exige `permission_handler_android` 14.x.
- En el `AndroidManifest.xml`: los permisos `CAMERA` y `NFC`, y `uses-feature` de cámara y NFC con `required="false"` para poder instalarse en dispositivos sin ellos.

**iOS** (`ios/Runner`)
- `Info.plist`: `NSCameraUsageDescription`, `NFCReaderUsageDescription` y el AID NDEF en `com.apple.developer.nfc.readersession.iso7816.select-identifiers`.
- `Runner.entitlements`: `com.apple.developer.nfc.readersession.formats` con `NDEF` y `TAG`. Está referenciado desde `CODE_SIGN_ENTITLEMENTS`.
- Los plugins se integran con Swift Package Manager (no hay Podfile). `permission_handler` activa el permiso de cámara solo porque detecta `NSCameraUsageDescription`. Si cambias el `Info.plist`, borra `~/Library/Developer/Xcode/DerivedData` para que lo vuelva a leer.
- Para leer NFC en un iPhone hace falta firmar con una cuenta de Apple Developer de pago, con la capability *NFC Tag Reading* activada. El simulador no tiene ni cámara ni NFC.

## Qué probar

| Caso | Resultado esperado |
|---|---|
| Escanear un QR o un código de barras | Aparece en la lista y TalkBack / VoiceOver lo anuncian |
| Denegar el permiso de cámara | Botón "Conceder permiso"; si se deniega para siempre, "Abrir Ajustes" |
| Escanear un QR con una URL | Se muestra como texto y nunca se abre |
| Leer un tag NFC con texto | Muestra el texto. Un tag vacío muestra su UID en hexadecimal |
| Escribir un tag y volver a leerlo | Se lee el texto escrito |
| NFC apagado o dispositivo sin NFC (AC-06) | Mensaje explicativo, sin botones de NFC y sin crash |
| Cambiar de pestaña | Se libera la cámara: se apaga su indicador del sistema |
