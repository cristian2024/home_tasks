import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';

/// Repositorio del agregado [HouseholdItem] (con sus identificadores y su
/// historial). Las operaciones que escriben varias entidades son atómicas.
abstract interface class HouseholdItemRepository {
  /// Guarda un objeto nuevo, su identificador inicial (si lo hay) y sus
  /// eventos en una sola transacción. Lanza `IdentifierAlreadyBoundException`
  /// si el identificador ya existe.
  Future<void> createItem(
    HouseholdItem item, {
    PhysicalIdentifier? identifier,
    required List<ItemEvent> events,
  });

  /// Reemplaza el objeto y registra [event] en una sola transacción.
  Future<void> updateItem(HouseholdItem item, ItemEvent event);

  Future<HouseholdItem?> getById(String id);

  /// Emite el objeto (o `null` si no existe) cada vez que cambia.
  Stream<HouseholdItem?> watchById(String id);

  /// Todos los objetos, del modificado más recientemente al más antiguo.
  Stream<List<HouseholdItem>> watchAll();

  /// Objetos cuyo nombre contiene [query] (sin distinguir mayúsculas), del
  /// modificado más recientemente al más antiguo.
  Future<List<HouseholdItem>> searchByName(String query);

  Future<PhysicalIdentifier?> findIdentifier(String rawValue, IdentifierType type);

  /// Identificadores del objeto, del más antiguo al más reciente.
  Stream<List<PhysicalIdentifier>> watchIdentifiers(String itemId);

  /// Asocia [identifier] y registra [event] en una sola transacción. Lanza
  /// `IdentifierAlreadyBoundException` si el identificador ya existe.
  Future<void> bindIdentifier(PhysicalIdentifier identifier, ItemEvent event);

  Future<void> addEvent(ItemEvent event);

  /// Historial del objeto, del evento más reciente al más antiguo.
  Stream<List<ItemEvent>> watchEvents(String itemId);
}
