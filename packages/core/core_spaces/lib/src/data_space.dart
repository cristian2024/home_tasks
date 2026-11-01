import 'package:equatable/equatable.dart';

/// Un conjunto de datos con su propia base: local (sin hogar) o el de un hogar
/// de sincronización. Los datos de un espacio nunca se mezclan con los de otro.
class DataSpace extends Equatable {
  /// Lanza [ArgumentError] si [id], [name] o [databaseName] están en blanco, o
  /// si [householdId] no es `null` y está en blanco.
  DataSpace({
    required this.id,
    required this.name,
    required this.databaseName,
    required DateTime createdAt,
    this.householdId,
  }) : createdAt = createdAt.toUtc() {
    _checkNotBlank(id, 'id');
    _checkNotBlank(name, 'name');
    _checkNotBlank(databaseName, 'databaseName');
    if (householdId != null) {
      _checkNotBlank(householdId!, 'householdId');
    }
  }

  /// Un espacio nuevo, con la base `space_<id>` ([databaseNameFor]).
  factory DataSpace.create({required String id, required String name, required DateTime createdAt}) =>
      DataSpace(id: id, name: name, databaseName: databaseNameFor(id), createdAt: createdAt);

  /// Prefijo de las bases de los espacios creados con [DataSpace.create].
  static const String databasePrefix = 'space_';

  /// Nombre de la base de un espacio nuevo con [id].
  static String databaseNameFor(String id) => '$databasePrefix$id';

  /// UUID v4 del espacio.
  final String id;

  /// Nombre que ve el usuario (p. ej. «Casa» o «Oficina»).
  final String name;

  /// Nombre de su base de datos. No cambia nunca.
  final String databaseName;

  /// Creación, en UTC.
  final DateTime createdAt;

  /// Hogar de sincronización, o `null` si el espacio es local.
  final String? householdId;

  bool get isShared => householdId != null;

  /// Copia con otro [name] o, con [householdId], otro hogar (`null` para
  /// dejarlo local).
  DataSpace copyWith({String? name, String? Function()? householdId}) => DataSpace(
        id: id,
        name: name ?? this.name,
        databaseName: databaseName,
        createdAt: createdAt,
        householdId: householdId == null ? this.householdId : householdId(),
      );

  @override
  List<Object?> get props => <Object?>[id, name, databaseName, createdAt, householdId];
}

void _checkNotBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'No puede estar en blanco');
  }
}
