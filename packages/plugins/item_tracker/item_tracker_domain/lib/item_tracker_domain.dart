/// Dominio de item_tracker en Dart puro: entidades, reglas de validación y
/// jerarquía, errores y el contrato del repositorio. No depende de Flutter
/// ni de ningún motor de base de datos.
library;

export 'src/entities/household_item.dart';
export 'src/entities/item_event.dart';
export 'src/entities/physical_identifier.dart';
export 'src/errors/item_tracker_exception.dart';
export 'src/hierarchy/containment_policy.dart';
export 'src/hierarchy/item_tree.dart';
export 'src/item_validator.dart';
export 'src/repositories/household_item_repository.dart';
export 'src/value_objects/item_metadata.dart';
