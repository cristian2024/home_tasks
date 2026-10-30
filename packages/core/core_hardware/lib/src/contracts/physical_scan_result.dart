import 'package:equatable/equatable.dart';

enum ScanType { qr, barcode, nfc }

class PhysicalScanResult extends Equatable {
  /// Valor ya saneado (ver `ScannedValueSanitizer`). Sigue siendo texto no
  /// confiable: nunca se navega ni se ejecuta automáticamente.
  final String rawValue;
  final ScanType type;
  final DateTime scannedAt;

  PhysicalScanResult({
    required this.rawValue,
    required this.type,
    DateTime? scannedAt,
  }) : scannedAt = (scannedAt ?? DateTime.now()).toUtc();

  @override
  List<Object?> get props => <Object?>[rawValue, type, scannedAt];

  @override
  bool get stringify => true;
}
