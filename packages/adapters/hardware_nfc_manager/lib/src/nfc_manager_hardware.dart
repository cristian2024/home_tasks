import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart' show NfcIdentifierScanner;

import 'nfc_manager_scanner.dart';

/// Registra [NfcManagerScanner] como `NfcIdentifierScanner`. Es una
/// factoría: cada `get` devuelve un escáner nuevo, que quien lo pide libera
/// con `dispose()`. Quien compone la app solo lo elige:
///
/// ```dart
/// adapters: <DependencyModule>[NfcManagerHardware()]
/// ```
class NfcManagerHardware implements DependencyModule {
  const NfcManagerHardware();

  @override
  Future<void> register(ServiceLocator services) async =>
      services.registerFactory<NfcIdentifierScanner>(NfcManagerScanner.new);
}
