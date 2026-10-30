# hardware_mobile_scanner

Adaptador de `core_hardware` para la cámara: escanea QR y códigos de barras con [`mobile_scanner`](https://pub.dev/packages/mobile_scanner).

## Uso

Quien compone la app solo lo elige:

```dart
adapters: <DependencyModule>[MobileScannerHardware()]
```

`MobileScannerHardware` registra una **factoría** de `CameraIdentifierScanner` en el `ServiceLocator`: cada `get` devuelve un escáner nuevo. Quien lo pide (p. ej. una pantalla de escaneo) lo libera con `dispose()` al salir, y así la cámara se apaga.

La vista previa se muestra con `buildPreview()`, sin importar `mobile_scanner` fuera de este paquete.

## Configuración nativa

- Android: minSdk 24 y el permiso de cámara.
- iOS: `NSCameraUsageDescription` en `Info.plist`.

Consulta la app de ejemplo de `core_hardware`.

## Tests

```sh
flutter test
```

Prueban el registro en el locator y la traducción de formatos y errores. La lectura real necesita un dispositivo.
