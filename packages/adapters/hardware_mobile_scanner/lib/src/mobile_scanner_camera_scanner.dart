import 'dart:async';

import 'package:core_hardware/core_hardware.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// [CameraIdentifierScanner] sobre `mobile_scanner`.
///
/// El controlador de cámara se crea en el primer uso y se destruye en
/// [dispose], que la pantalla debe invocar al salir (spec §16).
///
/// `mobile_scanner` solo arranca la cámara con su widget montado: si no lo
/// está en 500 ms, falla y la vista previa queda en negro. Por eso, si
/// [startScanning] llega antes que la vista previa de [buildPreview], la
/// cámara arranca cuando esta se monta.
class MobileScannerCameraScanner implements CameraIdentifierScanner {
  MobileScannerCameraScanner({@visibleForTesting MobileScannerController Function()? controllerFactory})
      : _controllerFactory = controllerFactory ?? _defaultController;

  static MobileScannerController _defaultController() => MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
      );

  final MobileScannerController Function() _controllerFactory;
  MobileScannerController? _controller;

  /// Vistas previas montadas ahora.
  int _previews = 0;

  /// [startScanning] llegó sin vista previa montada.
  bool _startPending = false;
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
    final MobileScannerController controller = _ensureController();
    if (_previews == 0) {
      _startPending = true;
      return;
    }
    await _start(controller);
  }

  @override
  Future<void> stopScanning() async {
    _startPending = false;
    await _controller?.stop();
  }

  @override
  Widget buildPreview(
    BuildContext context, {
    Widget Function(BuildContext context, ScanException error)? errorBuilder,
    WidgetBuilder? placeholderBuilder,
  }) {
    return _PreviewMountTracker(
      onMounted: _onPreviewMounted,
      onUnmounted: _onPreviewUnmounted,
      child: MobileScanner(
        controller: _ensureController(),
        placeholderBuilder: placeholderBuilder,
        errorBuilder: (BuildContext context, MobileScannerException error) =>
            errorBuilder?.call(context, mapMobileScannerError(error)) ?? const SizedBox.shrink(),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _startPending = false;
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
    final MobileScannerController controller = _controllerFactory();
    _subscription = controller.barcodes.listen(_onCapture);
    return _controller = controller;
  }

  Future<void> _start(MobileScannerController controller) async {
    try {
      await controller.start();
    } on MobileScannerException catch (error) {
      _results.addError(mapMobileScannerError(error));
    }
  }

  /// Después del primer frame de la vista previa, con el widget de
  /// `mobile_scanner` ya unido al controlador.
  void _onPreviewMounted() {
    _previews++;
    final MobileScannerController? controller = _controller;
    if (_startPending && controller != null) {
      _startPending = false;
      unawaited(_start(controller));
    }
  }

  void _onPreviewUnmounted() => _previews--;

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

/// Avisa cuando su hijo ya está montado (después del primer frame) y cuando
/// se desmonta.
class _PreviewMountTracker extends StatefulWidget {
  const _PreviewMountTracker({required this.onMounted, required this.onUnmounted, required this.child});

  final VoidCallback onMounted;
  final VoidCallback onUnmounted;
  final Widget child;

  @override
  State<_PreviewMountTracker> createState() => _PreviewMountTrackerState();
}

class _PreviewMountTrackerState extends State<_PreviewMountTracker> {
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reported = true;
        widget.onMounted();
      }
    });
  }

  @override
  void dispose() {
    if (_reported) {
      widget.onUnmounted();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
