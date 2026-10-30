/// Adaptador de `core_hardware` con `nfc_manager`: lectura y escritura de
/// etiquetas NFC.
///
/// Quien compone la app solo elige [NfcManagerHardware]; los plugins piden
/// `NfcIdentifierScanner` al `ServiceLocator`.
library;

export 'src/nfc_manager_hardware.dart';
export 'src/nfc_manager_scanner.dart' show NfcManagerScanner;
