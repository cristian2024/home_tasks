import 'dart:async';

import 'package:core_hardware/core_hardware.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// [CameraIdentifierScanner] sobre `mobile_scanner`.
///
/// El controlador de cámara se crea en el primer uso y se destruye en
/// [dispose], que la pantalla debe invocar al salir (spec §16).
class MobileScannerCameraScanner implements CameraIdentifierScanner {
  MobileScannerController? _controller;
  StreamSubscription<BarcodeCapture>? _subscription;
  final StreamController<PhysicalScanResult> _results = StreamController<PhysicalScanResult>.broadcast();

  @override
  Stream<PhysicalScanResult> get scanStream => _results.stream;

  /// `mobile_scanner` no expone si existe una cámara; todos los dispositivos
  /// soportados la tienen. Los fallos reales llegan al iniciar.
  @override
  Future<HardwareStatus> checkHardware() async => HardwareStatus.available;

  @override
  Future<void> startScanning() async {
    try {
      await _ensureController().start();
    } on MobileScannerException catch (error) {
      _results.addError(mapMobileScannerError(error));
    }
  }

  @override
  Future<void> stopScanning() async {
    await _controller?.stop();
  }

  @override
  Widget buildPreview(
    BuildContext context, {
    Widget Function(BuildContext context, ScanException error)? errorBuilder,
    WidgetBuilder? placeholderBuilder,
  }) {
    return MobileScanner(
      controller: _ensureController(),
      placeholderBuilder: placeholderBuilder,
      errorBuilder: (BuildContext context, MobileScannerException error) =>
          errorBuilder?.call(context, mapMobileScannerError(error)) ?? const SizedBox.shrink(),
    );
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.dispose();
    _controller = null;
    await _results.close();
  }

  MobileScannerController _ensureController() {
    final MobileScannerController? existing = _controller;
    if (existing != null) {
      return existing;
    }
    final MobileScannerController controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _subscription = controller.barcodes.listen(_onCapture);
    return _controller = controller;
  }

  void _onCapture(BarcodeCapture capture) {
    for (final Barcode barcode in capture.barcodes) {
      final String? raw = barcode.rawValue;
      if (raw == null) {
        continue;
      }
      try {
        _results.add(
          PhysicalScanResult(
            rawValue: ScannedValueSanitizer.sanitize(raw),
            type: scanTypeForFormat(barcode.format),
          ),
        );
      } on ScanException catch (error) {
        _results.addError(error);
      }
    }
  }
}

@visibleForTesting
ScanType scanTypeForFormat(BarcodeFormat format) =>
    format == BarcodeFormat.qrCode ? ScanType.qr : ScanType.barcode;

@visibleForTesting
ScanException mapMobileScannerError(MobileScannerException error) {
  final ScanErrorCode code = switch (error.errorCode) {
    MobileScannerErrorCode.permissionDenied => ScanErrorCode.permissionDenied,
    MobileScannerErrorCode.unsupported => ScanErrorCode.hardwareUnsupported,
    _ => ScanErrorCode.unknown,
  };
  return ScanException(code, message: error.errorDetails?.message, cause: error);
}
