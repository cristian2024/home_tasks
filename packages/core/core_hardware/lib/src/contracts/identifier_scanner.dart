import 'package:flutter/widgets.dart';

import 'hardware_status.dart';
import 'physical_scan_result.dart';
import 'scan_exception.dart';

/// Fuente de identificadores físicos. Cada instancia pertenece a una pantalla:
/// se crea al entrar y se libera con [dispose] al salir (spec §16).
abstract interface class IdentifierScanner {
  /// Stream broadcast de lecturas. Los fallos llegan como errores de tipo
  /// [ScanException]; el stream no se cierra hasta [dispose].
  Stream<PhysicalScanResult> get scanStream;

  Future<HardwareStatus> checkHardware();

  /// Inicia la lectura. Si el hardware no está disponible o falta un permiso,
  /// emite una [ScanException] en [scanStream] en lugar de lanzar.
  Future<void> startScanning();

  Future<void> stopScanning();

  /// Detiene la lectura, libera el hardware y cierra [scanStream].
  Future<void> dispose();
}

/// Escáner de códigos QR y de barras con la cámara.
abstract interface class CameraIdentifierScanner implements IdentifierScanner {
  /// Previsualización de la cámara. Es la única forma de mostrarla sin que la
  /// presentación importe paquetes nativos.
  Widget buildPreview(
    BuildContext context, {
    Widget Function(BuildContext context, ScanException error)? errorBuilder,
    WidgetBuilder? placeholderBuilder,
  });
}

/// Lector y escritor de tags NFC (NDEF).
abstract interface class NfcIdentifierScanner implements IdentifierScanner {
  /// Escribe [value] como registro NDEF de texto en el próximo tag que se
  /// acerque. Completa al terminar la escritura o lanza [ScanException].
  /// No puede usarse mientras haya una lectura en curso.
  Future<void> writeTag(String value);
}
