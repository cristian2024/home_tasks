/// Evento publicado en el `EventBus` para comunicar plugins sin acoplarlos.
///
/// Los eventos de cada plugin se definen en su contrato
/// (`packages/contracts/<funcionalidad>_contract`), nunca en el plugin.
abstract class CrossPluginEvent {
  /// Quien publica pasa siempre [emittedAt] desde su `Clock`, para que los
  /// tests puedan fijarlo. Si falta se usa la hora actual (respaldo). Siempre
  /// se guarda en UTC.
  CrossPluginEvent({DateTime? emittedAt}) : emittedAt = (emittedAt ?? DateTime.now()).toUtc();

  final DateTime emittedAt;
}

class ItemCreatedCrossEvent extends CrossPluginEvent {
  final String itemId;
  final String itemName;

  ItemCreatedCrossEvent({required this.itemId, required this.itemName, super.emittedAt});
}
