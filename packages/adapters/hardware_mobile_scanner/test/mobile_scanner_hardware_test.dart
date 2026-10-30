import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart' show CameraIdentifierScanner, HardwareStatus, ScanErrorCode, ScanType;
import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_mobile_scanner/hardware_mobile_scanner.dart';
import 'package:hardware_mobile_scanner/src/mobile_scanner_camera_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  test('registra una factoría de CameraIdentifierScanner: un escáner nuevo en cada get', () async {
    final ServiceLocator locator = ServiceLocator();
    addTearDown(locator.reset);

    await const MobileScannerHardware().register(locator);

    final CameraIdentifierScanner first = locator.get<CameraIdentifierScanner>();
    final CameraIdentifierScanner second = locator.get<CameraIdentifierScanner>();
    expect(first, isA<MobileScannerCameraScanner>());
    expect(identical(first, second), isFalse);
    expect(await first.checkHardware(), HardwareStatus.available);
  });

  test('el formato QR se mapea a ScanType.qr y el resto a barcode', () {
    expect(scanTypeForFormat(BarcodeFormat.qrCode), ScanType.qr);
    expect(scanTypeForFormat(BarcodeFormat.ean13), ScanType.barcode);
    expect(scanTypeForFormat(BarcodeFormat.code128), ScanType.barcode);
  });

  test('los errores de mobile_scanner se traducen a ScanErrorCode', () {
    ScanErrorCode map(MobileScannerErrorCode code) =>
        mapMobileScannerError(MobileScannerException(errorCode: code)).code;

    expect(map(MobileScannerErrorCode.permissionDenied), ScanErrorCode.permissionDenied);
    expect(map(MobileScannerErrorCode.unsupported), ScanErrorCode.hardwareUnsupported);
    expect(map(MobileScannerErrorCode.genericError), ScanErrorCode.unknown);
  });
}
