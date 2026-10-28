import 'package:core_di/core_di.dart';
import 'package:isar_community/isar.dart';

/// Adaptador Isar de una funcionalidad (p. ej. `item_tracker_isar`).
///
/// Aporta sus colecciones y, con la base ya abierta, registra en el
/// [ServiceLocator] las implementaciones Isar de sus contratos. Lo llama
/// `IsarStorage`; nadie más necesita usar sus miembros.
abstract interface class IsarFeature {
  List<CollectionSchema<dynamic>> get schemas;

  void register(ServiceLocator services, Isar isar);
}
