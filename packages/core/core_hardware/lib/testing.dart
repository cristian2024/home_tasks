/// Dobles de prueba de los contratos de hardware, para los tests de los
/// paquetes que los consumen.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'core_hardware.dart';

class FakeIdentifierScanner implements IdentifierScanner {
  FakeIdentifierScanner({this.type = ScanType.qr, this.hardwareStatus = HardwareStatus.available});

  final ScanType type;
  HardwareStatus hardwareStatus;
  bool isScanning = false;
  bool isDisposed = false;

  final StreamController<PhysicalScanResult> _results = StreamController<PhysicalScanResult>.broadcast();

  @override
  Stream<PhysicalScanResult> get scanStream => _results.stream;

  @override
  Future<HardwareStatus> checkHardware() async => hardwareStatus;

  @override
  Future<void> startScanning() async {
    switch (hardwareStatus) {
      case HardwareStatus.available:
        isScanning = true;
      case HardwareStatus.disabled:
        _results.addError(const ScanException(ScanErrorCode.hardwareDisabled));
      case HardwareStatus.unsupported:
        _results.addError(const ScanException(ScanErrorCode.hardwareUnsupported));
    }
  }

  @override
  Future<void> stopScanning() async => isScanning = false;

  /// Simula una lectura, aplicando el mismo saneamiento que los adaptadores.
  void emit(String rawValue) {
    try {
      _results.add(
        PhysicalScanResult(rawValue: ScannedValueSanitizer.sanitize(rawValue), type: type),
      );
    } on ScanException catch (error) {
      _results.addError(error);
    }
  }

  void emitError(ScanException error) => _results.addError(error);

  @override
  Future<void> dispose() async {
    isScanning = false;
    isDisposed = true;
    await _results.close();
  }
}

class FakeCameraScanner extends FakeIdentifierScanner implements CameraIdentifierScanner {
  FakeCameraScanner({super.type, super.hardwareStatus});

  static const Key previewKey = Key('fake_camera_preview');

  @override
  Widget buildPreview(
    BuildContext context, {
    Widget Function(BuildContext context, ScanException error)? errorBuilder,
    WidgetBuilder? placeholderBuilder,
  }) =>
      const SizedBox(key: previewKey);
}

class FakeNfcScanner extends FakeIdentifierScanner implements NfcIdentifierScanner {
  FakeNfcScanner({super.hardwareStatus}) : super(type: ScanType.nfc);

  final List<String> writtenValues = <String>[];
  ScanException? writeError;

  @override
  Future<void> writeTag(String value) async {
    final ScanException? error = writeError;
    if (error != null) {
      throw error;
    }
    writtenValues.add(ScannedValueSanitizer.sanitize(value));
  }
}

class FakeHardwarePermissions implements HardwarePermissions {
  FakeHardwarePermissions({this.status = HardwarePermissionStatus.granted, this.statusAfterRequest});

  HardwarePermissionStatus status;
  HardwarePermissionStatus? statusAfterRequest;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<HardwarePermissionStatus> cameraStatus() async => status;

  @override
  Future<HardwarePermissionStatus> requestCamera() async {
    requestCalls++;
    if (status == HardwarePermissionStatus.denied && statusAfterRequest != null) {
      status = statusAfterRequest!;
    }
    return status;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }
}
