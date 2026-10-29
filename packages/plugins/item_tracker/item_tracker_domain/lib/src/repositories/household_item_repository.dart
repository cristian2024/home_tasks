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

  /// Todos los objetos, sin orden garantizado.
  Future<List<HouseholdItem>> getAll();

  /// Reemplaza el objeto (con su nuevo `parentId`) y registra [events] (en el
  /// objeto y en sus contenedores) en una sola transacción.
  Future<void> moveItem(HouseholdItem item, List<ItemEvent> events);

  /// Borra los objetos [itemIds] con borrado lógico (spec §10.3), junto con
  /// sus identificadores activos, que quedan libres para asociarse a otro
  /// objeto. En la misma transacción reemplaza [moved] (p. ej. el contenido
  /// que sale al contenedor) y registra [events]. Desde entonces ningún
  /// método devuelve los objetos borrados. Los que no existen o ya se
  /// borraron se ignoran.
  Future<void> deleteItems(
    List<String> itemIds, {
    required DateTime deletedAt,
    List<HouseholdItem> moved = const <HouseholdItem>[],
    required List<ItemEvent> events,
  });

  /// Emite el objeto (o `null` si no existe) cada vez que cambia.
  Stream<HouseholdItem?> watchById(String id);

  /// Todos los objetos, del modificado más recientemente al más antiguo.
  Stream<List<HouseholdItem>> watchAll();

  /// Objetos cuyo nombre contiene [query] (sin distinguir mayúsculas), del
  /// modificado más recientemente al más antiguo.
  Future<List<HouseholdItem>> searchByName(String query);

  /// Identificador activo con ese valor y tipo. Los quitados no cuentan.
  Future<PhysicalIdentifier?> findIdentifier(String rawValue, IdentifierType type);

  /// Identificador activo con ese [id]; `null` si no existe o se quitó.
  Future<PhysicalIdentifier?> getIdentifier(String id);

  /// Identificadores activos del objeto, del más antiguo al más reciente.
  Stream<List<PhysicalIdentifier>> watchIdentifiers(String itemId);

  /// Asocia [identifier] y registra [event] en una sola transacción. Lanza
  /// `IdentifierAlreadyBoundException` si el identificador ya existe.
  Future<void> bindIdentifier(PhysicalIdentifier identifier, ItemEvent event);

  /// Quita el identificador con borrado lógico (spec §10.3) y registra
  /// [event] en una sola transacción. Después el mismo valor y tipo se puede
  /// asociar de nuevo a cualquier objeto.
  Future<void> unbindIdentifier(String identifierId, {required DateTime deletedAt, required ItemEvent event});

  Future<void> addEvent(ItemEvent event);

  /// Historial del objeto, del evento más reciente al más antiguo.
  Stream<List<ItemEvent>> watchEvents(String itemId);
}
