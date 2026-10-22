// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_plugin_preference.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPluginPreferenceCollection on Isar {
  IsarCollection<IsarPluginPreference> get isarPluginPreferences =>
      this.collection();
}

const IsarPluginPreferenceSchema = CollectionSchema(
  name: r'IsarPluginPreference',
  id: 8780927744613002501,
  properties: {
    r'isEnabled': PropertySchema(
      id: 0,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'pluginId': PropertySchema(
      id: 1,
      name: r'pluginId',
      type: IsarType.string,
    ),
    r'sortOrder': PropertySchema(
      id: 2,
      name: r'sortOrder',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarPluginPreferenceEstimateSize,
  serialize: _isarPluginPreferenceSerialize,
  deserialize: _isarPluginPreferenceDeserialize,
  deserializeProp: _isarPluginPreferenceDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'pluginId': IndexSchema(
      id: 414836295840914770,
      name: r'pluginId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'pluginId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarPluginPreferenceGetId,
  getLinks: _isarPluginPreferenceGetLinks,
  attach: _isarPluginPreferenceAttach,
  version: '3.3.2',
);

int _isarPluginPreferenceEstimateSize(
  IsarPluginPreference object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.pluginId.length * 3;
  return bytesCount;
}

void _isarPluginPreferenceSerialize(
  IsarPluginPreference object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isEnabled);
  writer.writeString(offsets[1], object.pluginId);
  writer.writeLong(offsets[2], object.sortOrder);
}

IsarPluginPreference _isarPluginPreferenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPluginPreference();
  object.isEnabled = reader.readBool(offsets[0]);
  object.isarId = id;
  object.pluginId = reader.readString(offsets[1]);
  object.sortOrder = reader.readLong(offsets[2]);
  return object;
}

P _isarPluginPreferenceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarPluginPreferenceGetId(IsarPluginPreference object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _isarPluginPreferenceGetLinks(
  IsarPluginPreference object,
) {
  return [];
}

void _isarPluginPreferenceAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarPluginPreference object,
) {
  object.isarId = id;
}

extension IsarPluginPreferenceByIndex on IsarCollection<IsarPluginPreference> {
  Future<IsarPluginPreference?> getByPluginId(String pluginId) {
    return getByIndex(r'pluginId', [pluginId]);
  }

  IsarPluginPreference? getByPluginIdSync(String pluginId) {
    return getByIndexSync(r'pluginId', [pluginId]);
  }

  Future<bool> deleteByPluginId(String pluginId) {
    return deleteByIndex(r'pluginId', [pluginId]);
  }

  bool deleteByPluginIdSync(String pluginId) {
    return deleteByIndexSync(r'pluginId', [pluginId]);
  }

  Future<List<IsarPluginPreference?>> getAllByPluginId(
    List<String> pluginIdValues,
  ) {
    final values = pluginIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'pluginId', values);
  }

  List<IsarPluginPreference?> getAllByPluginIdSync(
    List<String> pluginIdValues,
  ) {
    final values = pluginIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'pluginId', values);
  }

  Future<int> deleteAllByPluginId(List<String> pluginIdValues) {
    final values = pluginIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'pluginId', values);
  }

  int deleteAllByPluginIdSync(List<String> pluginIdValues) {
    final values = pluginIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'pluginId', values);
  }

  Future<Id> putByPluginId(IsarPluginPreference object) {
    return putByIndex(r'pluginId', object);
  }

  Id putByPluginIdSync(IsarPluginPreference object, {bool saveLinks = true}) {
    return putByIndexSync(r'pluginId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPluginId(List<IsarPluginPreference> objects) {
    return putAllByIndex(r'pluginId', objects);
  }

  List<Id> putAllByPluginIdSync(
    List<IsarPluginPreference> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'pluginId', objects, saveLinks: saveLinks);
  }
}

extension IsarPluginPreferenceQueryWhereSort
    on QueryBuilder<IsarPluginPreference, IsarPluginPreference, QWhere> {
  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarPluginPreferenceQueryWhere
    on QueryBuilder<IsarPluginPreference, IsarPluginPreference, QWhereClause> {
  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterWhereClause>
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterWhereClause>
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

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterWhereClause>
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterWhereClause>
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

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterWhereClause>
  pluginIdEqualTo(String pluginId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'pluginId', value: [pluginId]),
      );
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterWhereClause>
  pluginIdNotEqualTo(String pluginId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pluginId',
                lower: [],
                upper: [pluginId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pluginId',
                lower: [pluginId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pluginId',
                lower: [pluginId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pluginId',
                lower: [],
                upper: [pluginId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarPluginPreferenceQueryFilter
    on
        QueryBuilder<
          IsarPluginPreference,
          IsarPluginPreference,
          QFilterCondition
        > {
  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  isEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isEnabled', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
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
    IsarPluginPreference,
    IsarPluginPreference,
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
    IsarPluginPreference,
    IsarPluginPreference,
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
    IsarPluginPreference,
    IsarPluginPreference,
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
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pluginId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pluginId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pluginId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pluginId',
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
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'pluginId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'pluginId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'pluginId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'pluginId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pluginId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  pluginIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'pluginId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  sortOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sortOrder', value: value),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  sortOrderGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sortOrder',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  sortOrderLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sortOrder',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarPluginPreference,
    IsarPluginPreference,
    QAfterFilterCondition
  >
  sortOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sortOrder',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarPluginPreferenceQueryObject
    on
        QueryBuilder<
          IsarPluginPreference,
          IsarPluginPreference,
          QFilterCondition
        > {}

extension IsarPluginPreferenceQueryLinks
    on
        QueryBuilder<
          IsarPluginPreference,
          IsarPluginPreference,
          QFilterCondition
        > {}

extension IsarPluginPreferenceQuerySortBy
    on QueryBuilder<IsarPluginPreference, IsarPluginPreference, QSortBy> {
  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  sortByPluginId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pluginId', Sort.asc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  sortByPluginIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pluginId', Sort.desc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  sortBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  sortBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }
}

extension IsarPluginPreferenceQuerySortThenBy
    on QueryBuilder<IsarPluginPreference, IsarPluginPreference, QSortThenBy> {
  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  thenByPluginId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pluginId', Sort.asc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  thenByPluginIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pluginId', Sort.desc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  thenBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QAfterSortBy>
  thenBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }
}

extension IsarPluginPreferenceQueryWhereDistinct
    on QueryBuilder<IsarPluginPreference, IsarPluginPreference, QDistinct> {
  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QDistinct>
  distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QDistinct>
  distinctByPluginId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pluginId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPluginPreference, IsarPluginPreference, QDistinct>
  distinctBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sortOrder');
    });
  }
}

extension IsarPluginPreferenceQueryProperty
    on
        QueryBuilder<
          IsarPluginPreference,
          IsarPluginPreference,
          QQueryProperty
        > {
  QueryBuilder<IsarPluginPreference, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<IsarPluginPreference, bool, QQueryOperations>
  isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<IsarPluginPreference, String, QQueryOperations>
  pluginIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pluginId');
    });
  }

  QueryBuilder<IsarPluginPreference, int, QQueryOperations>
  sortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sortOrder');
    });
  }
}
