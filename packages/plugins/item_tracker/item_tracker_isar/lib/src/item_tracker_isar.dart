import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:storage_isar/adapter.dart';

import 'models/isar_household_item.dart';
import 'models/isar_item_event.dart';
import 'models/isar_item_tracker_synced.dart';
import 'models/isar_physical_identifier.dart';
import 'repositories/isar_household_item_repository.dart';

/// Adaptador Isar de item_tracker. Quien compone la app solo lo elige, dentro
/// de `IsarStorage(features: <IsarFeature>[ItemTrackerIsar()])`, también si el
/// plugin está desactivado.
///
/// Con la base abierta registra `HouseholdItemRepository` en el
/// `ServiceLocator` y añade su `ItemTrackerSyncParticipant` a
/// `SyncParticipants`, en el scope raíz: un plugin desactivado sigue
/// recibiendo sus cambios. Si la app no compuso la sincronización, no se
/// registra nada en el log.
///
/// Las colecciones conservan los nombres que usaba `plugin_item_tracker`,
/// así que los datos ya guardados se siguen leyendo.
class ItemTrackerIsar implements IsarFeature {
  /// [containmentPolicy] es la del plugin; por defecto, la de
  /// `--dart-define=ITEM_TRACKER_MAX_DEPTH`.
  const ItemTrackerIsar({this.containmentPolicy});

  final ContainmentPolicy? containmentPolicy;

  @override
  List<CollectionSchema<dynamic>> get schemas => const <CollectionSchema<dynamic>>[
        IsarHouseholdItemSchema,
        IsarPhysicalIdentifierSchema,
        IsarItemEventSchema,
        IsarItemTrackerSyncedSchema,
      ];

  @override
  void register(ServiceLocator services, Isar isar) {
    final IsarHouseholdItemRepository repository = IsarHouseholdItemRepository(isar, services: services);
    services.registerSingleton<HouseholdItemRepository>(repository);
    SyncParticipants.of(services).add(ItemTrackerSyncParticipant(
      store: repository,
      repository: repository,
      resolver: ItemTrackerResolver(
        policy: containmentPolicy ??
            ContainmentPolicy.fromConfiguredDepth(
              const int.fromEnvironment('ITEM_TRACKER_MAX_DEPTH', defaultValue: ContainmentPolicy.defaultMaxDepth),
            ),
      ),
    ));
  }
}
