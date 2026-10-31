/// Dominio de la lista de compras en Dart puro: items, categorías e historial
/// de compras, reglas de validación, estado, filtro y agrupación, errores, el
/// contrato del repositorio y su sincronización. No depende de Flutter ni de ningún motor de base
/// de datos.
library;

export 'package:recurrence/recurrence.dart';
export 'package:urgency/urgency.dart';

export 'src/entities/shopping_category.dart';
export 'src/entities/shopping_item.dart';
export 'src/entities/shopping_purchase.dart';
export 'src/errors/shopping_list_exception.dart';
export 'src/list/shopping_list_view.dart';
export 'src/repositories/shopping_list_repository.dart';
export 'src/shopping_validator.dart';
export 'src/sync/shopping_list_codec.dart';
export 'src/sync/shopping_list_resolver.dart';
export 'src/sync/shopping_list_sync_participant.dart';
export 'src/sync/shopping_list_sync_store.dart';
