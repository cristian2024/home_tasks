import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/src/camera/mobile_scanner_camera_scanner.dart';
import 'package:core_hardware/src/permissions/permission_handler_permissions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
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

  test('los estados de permission_handler se traducen a HardwarePermissionStatus', () {
    expect(mapPermissionStatus(PermissionStatus.granted), HardwarePermissionStatus.granted);
    expect(mapPermissionStatus(PermissionStatus.limited), HardwarePermissionStatus.granted);
    expect(mapPermissionStatus(PermissionStatus.denied), HardwarePermissionStatus.denied);
    expect(
      mapPermissionStatus(PermissionStatus.permanentlyDenied),
      HardwarePermissionStatus.permanentlyDenied,
    );
    expect(mapPermissionStatus(PermissionStatus.restricted), HardwarePermissionStatus.restricted);
  });
}
