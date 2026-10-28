import 'package:core_storage/core_storage.dart';

import '../../domain/entities/physical_identifier.dart';

part 'isar_physical_identifier.g.dart';

@collection
class IsarPhysicalIdentifier {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  /// Un identificador físico activo (valor + tipo) solo puede estar ligado a
  /// un objeto. Sin `replace`: un duplicado hace fallar la transacción. Los
  /// quitados llevan su propio [deletedId], así que no chocan con el activo ni
  /// entre sí.
  @Index(composite: <CompositeIndex>[CompositeIndex('type'), CompositeIndex('deletedId')], unique: true)
  late String rawValue;

  @Enumerated(EnumType.name)
  late IdentifierType type;

  @Index()
  late String itemId;

  late DateTime boundAt;

  /// Borrado lógico (spec §10.3): `null` si está activo; el propio [id] si se
  /// quitó. Los registros anteriores a este campo se leen como activos.
  String? deletedId;

  /// Momento en que se quitó (UTC), para la futura sincronización.
  DateTime? deletedAt;

  bool get isDeleted => deletedId != null;
}
