import 'package:equatable/equatable.dart';

/// Tipo de identificador físico. Es propio del dominio: quien escanea lo
/// traduce desde el `ScanType` de core_hardware.
enum IdentifierType { qr, barcode, nfc }

class PhysicalIdentifier extends Equatable {
  final String id; // UUID v4
  final String rawValue;
  final IdentifierType type;
  final String itemId; // Foreign Key hacia HouseholdItem.id
  final DateTime boundAt; // UTC

  const PhysicalIdentifier({
    required this.id,
    required this.rawValue,
    required this.type,
    required this.itemId,
    required this.boundAt,
  });

  @override
  List<Object?> get props => <Object?>[id, rawValue, type, itemId, boundAt];

  @override
  bool get stringify => true;
}
