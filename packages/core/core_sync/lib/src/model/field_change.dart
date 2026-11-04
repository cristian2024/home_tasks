import 'package:equatable/equatable.dart';

import 'json.dart';

/// Cambio de un campo de una entidad dentro de un [ChangeRecord].
sealed class FieldChange extends Equatable {
  FieldChange(this.field) {
    checkNotEmpty(field, 'field');
  }

  /// Lee un cambio escrito con [toJson]. Lanza [FormatException] si no lo es.
  factory FieldChange.fromJson(Object? source) {
    final Map<String, Object?> json = asJsonMap(source);
    return parseJson(source, () {
      final String field = readJson<String>(json, 'field');
      return switch (readJson<String>(json, 'kind')) {
        'value' => ValueChange(field, json['value']),
        'element' => ElementChange(
            field,
            readJson<String>(json, 'element'),
            present: readJson<bool>(json, 'present'),
          ),
        final String kind => throw FormatException('Tipo de cambio desconocido: $kind', source),
      };
    });
  }

  final String field;

  Map<String, Object?> toJson();
}

/// El campo pasa a valer [value] (un valor JSON). Se fusiona por
/// last-write-wins.
final class ValueChange extends FieldChange {
  /// Lanza [ArgumentError] si [value] no es un valor JSON.
  ValueChange(super.field, this.value) {
    checkJsonValue(value, 'value');
  }

  final Object? value;

  @override
  Map<String, Object?> toJson() => <String, Object?>{'kind': 'value', 'field': field, 'value': value};

  @override
  List<Object?> get props => <Object?>[field, value];
}

/// Se añade ([present] `true`) o se quita [element] del conjunto [field]
/// (p. ej. un id de `categoryIds`). Se fusiona elemento a elemento.
final class ElementChange extends FieldChange {
  ElementChange(super.field, this.element, {required this.present}) {
    checkNotEmpty(element, 'element');
  }

  final String element;
  final bool present;

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': 'element', 'field': field, 'element': element, 'present': present};

  @override
  List<Object?> get props => <Object?>[field, element, present];
}
