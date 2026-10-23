// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_physical_identifier.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPhysicalIdentifierCollection on Isar {
  IsarCollection<IsarPhysicalIdentifier> get isarPhysicalIdentifiers =>
      this.collection();
}

const IsarPhysicalIdentifierSchema = CollectionSchema(
  name: r'IsarPhysicalIdentifier',
  id: -160842427406972117,
  properties: {
    r'boundAt': PropertySchema(
      id: 0,
      name: r'boundAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 1,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'deletedId': PropertySchema(
      id: 2,
      name: r'deletedId',
      type: IsarType.string,
    ),
    r'id': PropertySchema(id: 3, name: r'id', type: IsarType.string),
    r'isDeleted': PropertySchema(
      id: 4,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'itemId': PropertySchema(id: 5, name: r'itemId', type: IsarType.string),
    r'rawValue': PropertySchema(
      id: 6,
      name: r'rawValue',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 7,
      name: r'type',
      type: IsarType.string,
      enumMap: _IsarPhysicalIdentifiertypeEnumValueMap,
    ),
  },

  estimateSize: _isarPhysicalIdentifierEstimateSize,
  serialize: _isarPhysicalIdentifierSerialize,
  deserialize: _isarPhysicalIdentifierDeserialize,
  deserializeProp: _isarPhysicalIdentifierDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'rawValue_type_deletedId': IndexSchema(
      id: 7313818072187095099,
      name: r'rawValue_type_deletedId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'rawValue',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'deletedId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'itemId': IndexSchema(
      id: -5342806140158601489,
      name: r'itemId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'itemId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarPhysicalIdentifierGetId,
  getLinks: _isarPhysicalIdentifierGetLinks,
  attach: _isarPhysicalIdentifierAttach,
  version: '3.3.2',
);

int _isarPhysicalIdentifierEstimateSize(
  IsarPhysicalIdentifier object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.deletedId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.itemId.length * 3;
  bytesCount += 3 + object.rawValue.length * 3;
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _isarPhysicalIdentifierSerialize(
  IsarPhysicalIdentifier object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.boundAt);
  writer.writeDateTime(offsets[1], object.deletedAt);
  writer.writeString(offsets[2], object.deletedId);
  writer.writeString(offsets[3], object.id);
  writer.writeBool(offsets[4], object.isDeleted);
  writer.writeString(offsets[5], object.itemId);
  writer.writeString(offsets[6], object.rawValue);
  writer.writeString(offsets[7], object.type.name);
}

IsarPhysicalIdentifier _isarPhysicalIdentifierDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPhysicalIdentifier();
  object.boundAt = reader.readDateTime(offsets[0]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[1]);
  object.deletedId = reader.readStringOrNull(offsets[2]);
  object.id = reader.readString(offsets[3]);
  object.isarId = id;
  object.itemId = reader.readString(offsets[5]);
  object.rawValue = reader.readString(offsets[6]);
  object.type =
      _IsarPhysicalIdentifiertypeValueEnumMap[reader.readStringOrNull(
        offsets[7],
      )] ??
      IdentifierType.qr;
  return object;
}

P _isarPhysicalIdentifierDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (_IsarPhysicalIdentifiertypeValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              IdentifierType.qr)
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _IsarPhysicalIdentifiertypeEnumValueMap = {
  r'qr': r'qr',
  r'barcode': r'barcode',
  r'nfc': r'nfc',
};
const _IsarPhysicalIdentifiertypeValueEnumMap = {
  r'qr': IdentifierType.qr,
  r'barcode': IdentifierType.barcode,
  r'nfc': IdentifierType.nfc,
};

Id _isarPhysicalIdentifierGetId(IsarPhysicalIdentifier object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _isarPhysicalIdentifierGetLinks(
  IsarPhysicalIdentifier object,
) {
  return [];
}

void _isarPhysicalIdentifierAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarPhysicalIdentifier object,
) {
  object.isarId = id;
}

extension IsarPhysicalIdentifierByIndex
    on IsarCollection<IsarPhysicalIdentifier> {
  Future<IsarPhysicalIdentifier?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  IsarPhysicalIdentifier? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<IsarPhysicalIdentifier?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<IsarPhysicalIdentifier?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(IsarPhysicalIdentifier object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(IsarPhysicalIdentifier object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<IsarPhysicalIdentifier> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(
    List<IsarPhysicalIdentifier> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }

  Future<IsarPhysicalIdentifier?> getByRawValueTypeDeletedId(
    String rawValue,
    IdentifierType type,
    String? deletedId,
  ) {
    return getByIndex(r'rawValue_type_deletedId', [rawValue, type, deletedId]);
  }

  IsarPhysicalIdentifier? getByRawValueTypeDeletedIdSync(
    String rawValue,
    IdentifierType type,
    String? deletedId,
  ) {
    return getByIndexSync(r'rawValue_type_deletedId', [
      rawValue,
      type,
      deletedId,
    ]);
  }

  Future<bool> deleteByRawValueTypeDeletedId(
    String rawValue,
    IdentifierType type,
    String? deletedId,
  ) {
    return deleteByIndex(r'rawValue_type_deletedId', [
      rawValue,
      type,
      deletedId,
    ]);
  }

  bool deleteByRawValueTypeDeletedIdSync(
    String rawValue,
    IdentifierType type,
    String? deletedId,
  ) {
    return deleteByIndexSync(r'rawValue_type_deletedId', [
      rawValue,
      type,
      deletedId,
    ]);
  }

  Future<List<IsarPhysicalIdentifier?>> getAllByRawValueTypeDeletedId(
    List<String> rawValueValues,
    List<IdentifierType> typeValues,
    List<String?> deletedIdValues,
  ) {
    final len = rawValueValues.length;
    assert(
      typeValues.length == len && deletedIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([rawValueValues[i], typeValues[i], deletedIdValues[i]]);
    }

    return getAllByIndex(r'rawValue_type_deletedId', values);
  }

  List<IsarPhysicalIdentifier?> getAllByRawValueTypeDeletedIdSync(
    List<String> rawValueValues,
    List<IdentifierType> typeValues,
    List<String?> deletedIdValues,
  ) {
    final len = rawValueValues.length;
    assert(
      typeValues.length == len && deletedIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([rawValueValues[i], typeValues[i], deletedIdValues[i]]);
    }

    return getAllByIndexSync(r'rawValue_type_deletedId', values);
  }

  Future<int> deleteAllByRawValueTypeDeletedId(
    List<String> rawValueValues,
    List<IdentifierType> typeValues,
    List<String?> deletedIdValues,
  ) {
    final len = rawValueValues.length;
    assert(
      typeValues.length == len && deletedIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([rawValueValues[i], typeValues[i], deletedIdValues[i]]);
    }

    return deleteAllByIndex(r'rawValue_type_deletedId', values);
  }

  int deleteAllByRawValueTypeDeletedIdSync(
    List<String> rawValueValues,
    List<IdentifierType> typeValues,
    List<String?> deletedIdValues,
  ) {
    final len = rawValueValues.length;
    assert(
      typeValues.length == len && deletedIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([rawValueValues[i], typeValues[i], deletedIdValues[i]]);
    }

    return deleteAllByIndexSync(r'rawValue_type_deletedId', values);
  }

  Future<Id> putByRawValueTypeDeletedId(IsarPhysicalIdentifier object) {
    return putByIndex(r'rawValue_type_deletedId', object);
  }

  Id putByRawValueTypeDeletedIdSync(
    IsarPhysicalIdentifier object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(
      r'rawValue_type_deletedId',
      object,
      saveLinks: saveLinks,
    );
  }

  Future<List<Id>> putAllByRawValueTypeDeletedId(
    List<IsarPhysicalIdentifier> objects,
  ) {
    return putAllByIndex(r'rawValue_type_deletedId', objects);
  }

  List<Id> putAllByRawValueTypeDeletedIdSync(
    List<IsarPhysicalIdentifier> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'rawValue_type_deletedId',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension IsarPhysicalIdentifierQueryWhereSort
    on QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QWhere> {
  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarPhysicalIdentifierQueryWhere
    on
        QueryBuilder<
          IsarPhysicalIdentifier,
          IsarPhysicalIdentifier,
          QWhereClause
        > {
  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'id', value: [id]),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [],
                upper: [id],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [id],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [id],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [],
                upper: [id],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  rawValueEqualToAnyTypeDeletedId(String rawValue) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'rawValue_type_deletedId',
          value: [rawValue],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  rawValueNotEqualToAnyTypeDeletedId(String rawValue) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [],
                upper: [rawValue],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [],
                upper: [rawValue],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  rawValueTypeEqualToAnyDeletedId(String rawValue, IdentifierType type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'rawValue_type_deletedId',
          value: [rawValue, type],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  rawValueEqualToTypeNotEqualToAnyDeletedId(
    String rawValue,
    IdentifierType type,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue],
                upper: [rawValue, type],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue, type],
                includeLower: false,
                upper: [rawValue],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue, type],
                includeLower: false,
                upper: [rawValue],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue],
                upper: [rawValue, type],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  rawValueTypeEqualToDeletedIdIsNull(String rawValue, IdentifierType type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'rawValue_type_deletedId',
          value: [rawValue, type, null],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  rawValueTypeEqualToDeletedIdIsNotNull(String rawValue, IdentifierType type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'rawValue_type_deletedId',
          lower: [rawValue, type, null],
          includeLower: false,
          upper: [rawValue, type],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  rawValueTypeDeletedIdEqualTo(
    String rawValue,
    IdentifierType type,
    String? deletedId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'rawValue_type_deletedId',
          value: [rawValue, type, deletedId],
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  rawValueTypeEqualToDeletedIdNotEqualTo(
    String rawValue,
    IdentifierType type,
    String? deletedId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue, type],
                upper: [rawValue, type, deletedId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue, type, deletedId],
                includeLower: false,
                upper: [rawValue, type],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue, type, deletedId],
                includeLower: false,
                upper: [rawValue, type],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'rawValue_type_deletedId',
                lower: [rawValue, type],
                upper: [rawValue, type, deletedId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  itemIdEqualTo(String itemId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'itemId', value: [itemId]),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterWhereClause
  >
  itemIdNotEqualTo(String itemId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'itemId',
                lower: [],
                upper: [itemId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'itemId',
                lower: [itemId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'itemId',
                lower: [itemId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'itemId',
                lower: [],
                upper: [itemId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarPhysicalIdentifierQueryFilter
    on
        QueryBuilder<
          IsarPhysicalIdentifier,
          IsarPhysicalIdentifier,
          QFilterCondition
        > {
  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  boundAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'boundAt', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  boundAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'boundAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  boundAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'boundAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  boundAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'boundAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedAt', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deletedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'deletedId'),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'deletedId'),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'deletedId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deletedId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deletedId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deletedId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'deletedId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'deletedId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'deletedId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'deletedId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  deletedIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deletedId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDeleted', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'itemId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'itemId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  itemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'itemId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawValue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawValue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawValue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawValue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawValue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawValue',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawValue',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawValue', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  rawValueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawValue', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeEqualTo(IdentifierType value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeGreaterThan(
    IdentifierType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeLessThan(
    IdentifierType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeBetween(
    IdentifierType lower,
    IdentifierType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPhysicalIdentifier,
    IsarPhysicalIdentifier,
    QAfterFilterCondition
  >
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }
}

extension IsarPhysicalIdentifierQueryObject
    on
        QueryBuilder<
          IsarPhysicalIdentifier,
          IsarPhysicalIdentifier,
          QFilterCondition
        > {}

extension IsarPhysicalIdentifierQueryLinks
    on
        QueryBuilder<
          IsarPhysicalIdentifier,
          IsarPhysicalIdentifier,
          QFilterCondition
        > {}

extension IsarPhysicalIdentifierQuerySortBy
    on QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QSortBy> {
  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByBoundAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boundAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByBoundAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boundAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByDeletedId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedId', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByDeletedIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedId', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByRawValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawValue', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByRawValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawValue', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension IsarPhysicalIdentifierQuerySortThenBy
    on
        QueryBuilder<
          IsarPhysicalIdentifier,
          IsarPhysicalIdentifier,
          QSortThenBy
        > {
  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByBoundAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boundAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByBoundAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'boundAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByDeletedId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedId', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByDeletedIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedId', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByRawValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawValue', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByRawValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawValue', Sort.desc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QAfterSortBy>
  thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension IsarPhysicalIdentifierQueryWhereDistinct
    on QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QDistinct> {
  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QDistinct>
  distinctByBoundAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'boundAt');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QDistinct>
  distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QDistinct>
  distinctByDeletedId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QDistinct>
  distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QDistinct>
  distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QDistinct>
  distinctByItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QDistinct>
  distinctByRawValue({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawValue', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IsarPhysicalIdentifier, QDistinct>
  distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension IsarPhysicalIdentifierQueryProperty
    on
        QueryBuilder<
          IsarPhysicalIdentifier,
          IsarPhysicalIdentifier,
          QQueryProperty
        > {
  QueryBuilder<IsarPhysicalIdentifier, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, DateTime, QQueryOperations>
  boundAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'boundAt');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, DateTime?, QQueryOperations>
  deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, String?, QQueryOperations>
  deletedIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedId');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, bool, QQueryOperations>
  isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, String, QQueryOperations>
  itemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemId');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, String, QQueryOperations>
  rawValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawValue');
    });
  }

  QueryBuilder<IsarPhysicalIdentifier, IdentifierType, QQueryOperations>
  typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
