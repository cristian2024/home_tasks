/// Adaptador Isar de item_tracker. Quien compone la app solo elige
/// [ItemTrackerIsar]; el plugin pide `HouseholdItemRepository` al
/// `ServiceLocator` sin saber que detrás hay Isar.
library;

export 'src/item_tracker_isar.dart';
