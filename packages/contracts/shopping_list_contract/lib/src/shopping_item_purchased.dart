import 'package:core_events/core_events.dart';

/// Se compró un item de la lista de compras (también uno recurrente, que
/// vuelve a quedar pendiente más adelante).
class ShoppingItemPurchased extends CrossPluginEvent {
  ShoppingItemPurchased({required this.itemId, required this.itemName, required DateTime purchasedAt})
      : super(emittedAt: purchasedAt);

  final String itemId;
  final String itemName;

  /// Cuándo se compró, en UTC.
  DateTime get purchasedAt => emittedAt;
}
