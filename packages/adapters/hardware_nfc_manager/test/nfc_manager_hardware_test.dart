import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart' show NfcIdentifierScanner;
import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_nfc_manager/hardware_nfc_manager.dart';

void main() {
  test('registra una factoría de NfcIdentifierScanner: un escáner nuevo en cada get', () async {
    final ServiceLocator locator = ServiceLocator();
    addTearDown(locator.reset);

    await const NfcManagerHardware().register(locator);

    final NfcIdentifierScanner first = locator.get<NfcIdentifierScanner>();
    expect(first, isA<NfcManagerScanner>());
    expect(identical(first, locator.get<NfcIdentifierScanner>()), isFalse);
  });
}
