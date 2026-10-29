/// API pública de la lista de compras para otros plugins.
///
/// - Evento: [ShoppingItemPurchased], en el `EventBus`.
/// - Capacidades: [ShoppingListQuery] y [ShoppingListWriter]. Las registra
///   la lista de compras en su scope del `ServiceLocator` mientras está
///   activa. Quien las usa las pide al locator cuando las necesita
///   (`isRegistered` y `get`) y sigue funcionando si no están.
library;

export 'package:urgency/urgency.dart' show Urgency;

export 'src/shopping_item_purchased.dart';
export 'src/shopping_item_request.dart';
export 'src/shopping_item_summary.dart';
export 'src/shopping_list_query.dart';
export 'src/shopping_list_writer.dart';
