import 'package:core_hardware/core_hardware.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher throwsScan(ScanErrorCode code) =>
    throwsA(isA<ScanException>().having((ScanException e) => e.code, 'code', code));

void main() {
  test('elimina caracteres de control', () {
    expect(ScannedValueSanitizer.sanitize('QR\x00-1\x1F23\x7F\n'), 'QR-123');
  });

  test('conserva espacios, unicode y URLs como texto literal', () {
    expect(ScannedValueSanitizer.sanitize(' Caja ñ '), ' Caja ñ ');
    expect(ScannedValueSanitizer.sanitize('https://example.com/x'), 'https://example.com/x');
  });

  test('acepta exactamente 2048 caracteres y rechaza más', () {
    expect(ScannedValueSanitizer.sanitize('a' * 2048), hasLength(2048));
    expect(() => ScannedValueSanitizer.sanitize('a' * 2049), throwsScan(ScanErrorCode.invalidValue));
  });

  test('la longitud se mide tras sanear', () {
    expect(ScannedValueSanitizer.sanitize('${'a' * 2048}\x00\x00'), hasLength(2048));
  });

  test('rechaza valores vacíos tras sanear', () {
    expect(() => ScannedValueSanitizer.sanitize(''), throwsScan(ScanErrorCode.invalidValue));
    expect(() => ScannedValueSanitizer.sanitize('\x00\r\n'), throwsScan(ScanErrorCode.invalidValue));
  });

  test('PhysicalScanResult normaliza scannedAt a UTC', () {
    final PhysicalScanResult result = PhysicalScanResult(rawValue: 'x', type: ScanType.qr, scannedAt: DateTime(2026));

    expect(result.scannedAt.isUtc, isTrue);
    expect(PhysicalScanResult(rawValue: 'x', type: ScanType.nfc).scannedAt.isUtc, isTrue);
  });
}
