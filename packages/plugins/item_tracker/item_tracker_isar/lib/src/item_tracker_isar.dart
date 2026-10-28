import 'package:core_di/core_di.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:storage_isar/adapter.dart';

import 'models/isar_household_item.dart';
import 'models/isar_item_event.dart';
import 'models/isar_physical_identifier.dart';
import 'repositories/isar_household_item_repository.dart';

/// Adaptador Isar de item_tracker. Quien compone la app solo lo elige, dentro
/// de `IsarStorage(features: <IsarFeature>[ItemTrackerIsar()])`, también si el
/// plugin está desactivado.
///
/// Con la base abierta registra `HouseholdItemRepository` en el
/// `ServiceLocator`. Las colecciones conservan los nombres que usaba
/// `plugin_item_tracker`, así que los datos ya guardados se siguen leyendo.
class ItemTrackerIsar implements IsarFeature {
  const ItemTrackerIsar();

  @override
  List<CollectionSchema<dynamic>> get schemas => const <CollectionSchema<dynamic>>[
        IsarHouseholdItemSchema,
        IsarPhysicalIdentifierSchema,
        IsarItemEventSchema,
      ];

  @override
  void register(ServiceLocator services, Isar isar) =>
      services.registerSingleton<HouseholdItemRepository>(IsarHouseholdItemRepository(isar));
}
