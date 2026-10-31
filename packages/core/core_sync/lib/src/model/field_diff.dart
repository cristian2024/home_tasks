import 'field_change.dart';

/// Diferencia entre dos versiones de los campos de una entidad.
abstract final class FieldDiff {
  /// Cambios para pasar de [before] a [after]. Sin [before] (entidad nueva),
  /// solo los campos con valor.
  ///
  /// Un valor `Set<String>` en [after] es un conjunto: genera un
  /// [ElementChange] por elemento añadido o quitado respecto a [before],
  /// donde puede estar como cualquier `Iterable` (la lista de una
  /// `SyncedEntity`). El resto genera un [ValueChange] si cambió; los mapas y
  /// las listas se comparan por contenido.
  static List<FieldChange> between(Map<String, Object?>? before, Map<String, Object?> after) => <FieldChange>[
        for (final MapEntry<String, Object?>(:String key, :Object? value) in after.entries)
          if (value is Set<String>)
            ..._elements(key, before?[key], value)
          else if (before == null ? value != null : !_deepEquals(before[key], value))
            ValueChange(key, value),
      ];

  static List<FieldChange> _elements(String field, Object? before, Set<String> after) {
    final Set<String> previous = before is Iterable ? before.whereType<String>().toSet() : const <String>{};
    return <FieldChange>[
      for (final String element in after.difference(previous)) ElementChange(field, element, present: true),
      for (final String element in previous.difference(after)) ElementChange(field, element, present: false),
    ];
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.entries.every((MapEntry<Object?, Object?> entry) => b.containsKey(entry.key) && _deepEquals(entry.value, b[entry.key]));
    }
    if (a is List && b is List) {
      return a.length == b.length && <int>[for (int i = 0; i < a.length; i++) i].every((int i) => _deepEquals(a[i], b[i]));
    }
    return a == b;
  }
}
