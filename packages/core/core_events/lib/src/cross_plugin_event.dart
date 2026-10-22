/// Evento publicado en el [EventBus] para comunicar plugins sin acoplarlos.
///
/// Los plugins no pueden importarse entre sí, así que todo evento que cruce
/// fronteras de plugin se define aquí.
abstract class CrossPluginEvent {
  final DateTime emittedAt;

  CrossPluginEvent() : emittedAt = DateTime.now().toUtc();
}

class ItemCreatedCrossEvent extends CrossPluginEvent {
  final String itemId;
  final String itemName;

  ItemCreatedCrossEvent({required this.itemId, required this.itemName});
}
