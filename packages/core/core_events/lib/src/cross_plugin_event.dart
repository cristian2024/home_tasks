/// Evento publicado en el `EventBus` para comunicar plugins sin acoplarlos.
///
/// Los eventos de cada plugin se definen en su contrato
/// (`packages/contracts/<funcionalidad>_contract`), nunca en el plugin.
abstract class CrossPluginEvent {
  /// [emittedAt] viene del `Clock` de quien publica, para que los tests
  /// puedan fijarlo. Siempre se guarda en UTC.
  CrossPluginEvent({required DateTime emittedAt}) : emittedAt = emittedAt.toUtc();

  final DateTime emittedAt;
}

class ItemCreatedCrossEvent extends CrossPluginEvent {
  final String itemId;
  final String itemName;

  ItemCreatedCrossEvent({required this.itemId, required this.itemName, required super.emittedAt});
}
