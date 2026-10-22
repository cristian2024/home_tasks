import 'package:core_storage/core_storage.dart';

import '../../domain/entities/physical_identifier.dart';

part 'isar_physical_identifier.g.dart';

@collection
class IsarPhysicalIdentifier {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  /// Un identificador físico (valor + tipo) solo puede estar ligado a un
  /// objeto. Sin `replace`: un duplicado hace fallar la transacción.
  @Index(composite: [CompositeIndex('type')], unique: true)
  late String rawValue;

  @Enumerated(EnumType.name)
  late IdentifierType type;

  @Index()
  late String itemId;

  late DateTime boundAt;
}
