import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FakeIdentifierScanner emite lecturas saneadas y errores de validación', () async {
    final scanner = FakeIdentifierScanner();
    final events = <Object>[];
    scanner.scanStream.listen(events.add, onError: events.add);

    scanner
      ..emit('QR\x00-123')
      ..emit('\x00');
    await scanner.dispose();

    expect((events[0] as PhysicalScanResult).rawValue, 'QR-123');
    expect((events[1] as ScanException).code, ScanErrorCode.invalidValue);
  });

  test('AC-06: un FakeNfcScanner sin hardware emite hardwareUnsupported al iniciar', () async {
    final scanner = FakeNfcScanner(hardwareStatus: HardwareStatus.unsupported);
    final expectation = expectLater(
      scanner.scanStream.first,
      throwsA(isA<ScanException>().having((e) => e.code, 'code', ScanErrorCode.hardwareUnsupported)),
    );

    await scanner.startScanning();

    await expectation;
    expect(scanner.isScanning, isFalse);
    await scanner.dispose();
  });
}
