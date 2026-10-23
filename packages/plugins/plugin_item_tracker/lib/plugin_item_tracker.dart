/// Plugin de identificación y seguimiento de objetos del hogar.
library;

export 'plugin_definition.dart';
export 'src/data/item_tracker_storage.dart';
export 'src/data/repositories/isar_household_item_repository.dart';
export 'src/domain/entities/household_item.dart';
export 'src/domain/entities/item_event.dart';
export 'src/domain/entities/physical_identifier.dart';
export 'src/domain/errors/item_tracker_exception.dart';
export 'src/domain/hierarchy/containment_policy.dart';
export 'src/domain/hierarchy/item_tree.dart';
export 'src/domain/item_validator.dart';
export 'src/domain/repositories/household_item_repository.dart';
export 'src/domain/use_cases/add_item_event.dart';
export 'src/domain/use_cases/bind_identifier.dart';
export 'src/domain/use_cases/create_item.dart';
export 'src/domain/use_cases/find_item_by_identifier.dart';
export 'src/domain/use_cases/item_queries.dart';
export 'src/domain/use_cases/move_item.dart';
export 'src/domain/use_cases/unbind_identifier.dart';
export 'src/domain/use_cases/update_item.dart';
export 'src/domain/value_objects/item_metadata.dart';
export 'src/item_tracker_dependencies.dart';
export 'src/presentation/item_tracker_routes.dart';
