import 'package:core_storage/core_storage.dart';

import 'models/isar_household_item.dart';
import 'models/isar_item_event.dart';
import 'models/isar_physical_identifier.dart';

/// Colecciones Isar del plugin. El plugin las expone como
/// `StorageSchemaContributor` para que la app abra la base con ellas.
const List<CollectionSchema<dynamic>> itemTrackerSchemas = <CollectionSchema<dynamic>>[
  IsarHouseholdItemSchema,
  IsarPhysicalIdentifierSchema,
  IsarItemEventSchema,
];
