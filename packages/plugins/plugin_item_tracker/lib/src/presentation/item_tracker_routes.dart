import '../domain/entities/physical_identifier.dart';

/// Rutas del plugin. Son absolutas y planas para que la app las añada tal
/// cual a su `GoRouter`. El identificador escaneado viaja en query params
/// (`value`, `type`) para que también funcionen como deep link.
abstract final class ItemTrackerRoutes {
  static const String base = '/item-tracker';
  static const String scan = '$base/scan';
  static const String items = '$base/items';
  static const String notFound = '$base/not-found';
  static const String create = '$base/item/create';
  static const String associate = '$base/item/associate';
  static const String detailPattern = '$base/item/:id';
  static const String editPattern = '$base/item/:id/edit';
  static const String addEventPattern = '$base/item/:id/event/add';

  static String detail(String itemId) => '$base/item/${Uri.encodeComponent(itemId)}';
  static String edit(String itemId) => '${detail(itemId)}/edit';
  static String addEvent(String itemId) => '${detail(itemId)}/event/add';

  /// [path] con el identificador en los query params.
  static String withIdentifier(String path, ({String rawValue, IdentifierType type}) identifier) =>
      Uri(path: path, queryParameters: {'value': identifier.rawValue, 'type': identifier.type.name}).toString();

  /// Lee el identificador de los query params; `null` si falta o es inválido.
  static ({String rawValue, IdentifierType type})? identifierFrom(Map<String, String> query) {
    final value = query['value'];
    final type = IdentifierType.values.asNameMap()[query['type']];
    if (value == null || value.isEmpty || type == null) {
      return null;
    }
    return (rawValue: value, type: type);
  }
}
