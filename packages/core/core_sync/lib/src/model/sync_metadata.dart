import 'package:equatable/equatable.dart';
import 'package:hlc/hlc.dart';

import 'change_record.dart';
import 'field_change.dart';
import 'json.dart';

/// Último cambio de un elemento de un conjunto: si quedó dentro ([present])
/// y con qué marca.
class ElementStamp extends Equatable {
  const ElementStamp(this.hlc, {required this.present});

  final Hlc hlc;
  final bool present;

  @override
  List<Object?> get props => <Object?>[hlc, present];
}

/// Metadatos de sincronización de una entidad: la marca del último cambio de
/// cada campo y de cada elemento de sus conjuntos.
///
/// [apply] fusiona cambios de forma idempotente y conmutativa: los mismos
/// cambios, en cualquier orden y con repeticiones, dan los mismos metadatos.
class SyncMetadata extends Equatable {
  SyncMetadata({
    Map<String, Hlc> fields = const <String, Hlc>{},
    Map<String, Map<String, ElementStamp>> elements = const <String, Map<String, ElementStamp>>{},
    this.createdHlc,
  })  : fields = Map<String, Hlc>.unmodifiable(fields),
        elements = Map<String, Map<String, ElementStamp>>.unmodifiable(<String, Map<String, ElementStamp>>{
          for (final MapEntry<String, Map<String, ElementStamp>> entry in elements.entries)
            entry.key: Map<String, ElementStamp>.unmodifiable(entry.value),
        });

  /// Lee metadatos escritos con [toJson]. Lanza [FormatException] si no lo
  /// son.
  factory SyncMetadata.fromJson(Object? source) {
    final Map<String, Object?> json = asJsonMap(source);
    return parseJson(source, () {
      final Map<String, Object?> fields = asJsonMap(json['fields']);
      final Map<String, Object?> elements = asJsonMap(json['elements']);
      final Object? created = json['created'];
      return SyncMetadata(
        fields: <String, Hlc>{
          for (final String field in fields.keys) field: Hlc.parse(readJson<String>(fields, field)),
        },
        elements: <String, Map<String, ElementStamp>>{
          for (final String field in elements.keys) field: _readElements(asJsonMap(elements[field])),
        },
        createdHlc: created == null ? null : Hlc.parse(readJson<String>(json, 'created')),
      );
    });
  }

  static final SyncMetadata empty = SyncMetadata();

  /// Marca del último cambio de cada campo de valor.
  final Map<String, Hlc> fields;

  /// Por conjunto, el último cambio de cada elemento.
  final Map<String, Map<String, ElementStamp>> elements;

  /// Menor marca aplicada: la del cambio que creó la entidad.
  final Hlc? createdHlc;

  /// Dispositivo que creó la entidad.
  String? get originDeviceId => createdHlc?.deviceId;

  /// Marca del último cambio de [field], o `null` si nunca cambió.
  Hlc? hlcOf(String field) => fields[field];

  /// Elementos presentes en el conjunto [field].
  Set<String> presentElements(String field) => <String>{
        for (final MapEntry<String, ElementStamp> entry in (elements[field] ?? const <String, ElementStamp>{}).entries)
          if (entry.value.present) entry.key,
      };

  /// Fusiona los cambios de [record]. Ver [apply].
  SyncMerge merge(ChangeRecord record) => apply(record.changes, record.hlc);

  /// Fusiona [changes], hechos con la marca [hlc].
  ///
  /// Gana el cambio con mayor marca: por campo en los [ValueChange] y por
  /// elemento en los [ElementChange]. Con la misma marca (el mismo cambio
  /// repetido) no gana. [SyncMerge.winning] son los cambios que hay que
  /// escribir en la entidad.
  SyncMerge apply(List<FieldChange> changes, Hlc hlc) {
    final Map<String, Hlc> fields = Map<String, Hlc>.of(this.fields);
    final Map<String, Map<String, ElementStamp>> elements = <String, Map<String, ElementStamp>>{
      for (final MapEntry<String, Map<String, ElementStamp>> entry in this.elements.entries)
        entry.key: Map<String, ElementStamp>.of(entry.value),
    };
    final List<FieldChange> winning = <FieldChange>[];
    for (final FieldChange change in changes) {
      switch (change) {
        case ValueChange():
          final Hlc? current = fields[change.field];
          if (current == null || hlc.isAfter(current)) {
            fields[change.field] = hlc;
            winning.add(change);
          }
        case ElementChange():
          final Map<String, ElementStamp> stamps = elements.putIfAbsent(change.field, () => <String, ElementStamp>{});
          final ElementStamp? current = stamps[change.element];
          if (current == null || hlc.isAfter(current.hlc)) {
            stamps[change.element] = ElementStamp(hlc, present: change.present);
            winning.add(change);
          }
      }
    }
    final Hlc? created = createdHlc;
    return SyncMerge(
      SyncMetadata(
        fields: fields,
        elements: elements,
        createdHlc: created == null || hlc.isBefore(created) ? hlc : created,
      ),
      winning,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'fields': <String, Object?>{
          for (final MapEntry<String, Hlc> entry in fields.entries) entry.key: entry.value.encode(),
        },
        'elements': <String, Object?>{
          for (final MapEntry<String, Map<String, ElementStamp>> field in elements.entries)
            field.key: <String, Object?>{
              for (final MapEntry<String, ElementStamp> element in field.value.entries)
                element.key: <String, Object?>{'hlc': element.value.hlc.encode(), 'present': element.value.present},
            },
        },
        'created': createdHlc?.encode(),
      };

  static Map<String, ElementStamp> _readElements(Map<String, Object?> json) => <String, ElementStamp>{
        for (final String element in json.keys)
          element: ElementStamp(
            Hlc.parse(readJson<String>(asJsonMap(json[element]), 'hlc')),
            present: readJson<bool>(asJsonMap(json[element]), 'present'),
          ),
      };

  @override
  List<Object?> get props => <Object?>[fields, elements, createdHlc];
}

/// Resultado de [SyncMetadata.apply]: los metadatos nuevos y los cambios que
/// ganaron.
class SyncMerge extends Equatable {
  SyncMerge(this.metadata, List<FieldChange> winning) : winning = List<FieldChange>.unmodifiable(winning);

  final SyncMetadata metadata;
  final List<FieldChange> winning;

  /// Si algún cambio ganó (hay que escribir la entidad).
  bool get changed => winning.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[metadata, winning];
}
