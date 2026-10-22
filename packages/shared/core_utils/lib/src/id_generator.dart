import 'package:uuid/uuid.dart';

/// Genera los identificadores de dominio. Se inyecta para poder fijar IDs en
/// los tests.
abstract interface class IdGenerator {
  /// Devuelve un UUID v4 nuevo en formato canónico (minúsculas, con guiones).
  String newId();
}

class UuidV4Generator implements IdGenerator {
  const UuidV4Generator();

  static const _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}

final _uuidV4Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Indica si [value] es un UUID v4 canónico.
bool isUuidV4(String value) => _uuidV4Pattern.hasMatch(value);
