// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCurrencySettingsCollection on Isar {
  IsarCollection<CurrencySettings> get currencySettings => this.collection();
}

const CurrencySettingsSchema = CollectionSchema(
  name: r'CurrencySettings',
  id: -8589445349524409492,
  properties: {
    r'isMultiCurrencyEnabled': PropertySchema(
      id: 0,
      name: r'isMultiCurrencyEnabled',
      type: IsarType.bool,
    ),
    r'localCurrency': PropertySchema(
      id: 1,
      name: r'localCurrency',
      type: IsarType.string,
    ),
    r'referenceCurrency': PropertySchema(
      id: 2,
      name: r'referenceCurrency',
      type: IsarType.string,
    )
  },
  estimateSize: _currencySettingsEstimateSize,
  serialize: _currencySettingsSerialize,
  deserialize: _currencySettingsDeserialize,
  deserializeProp: _currencySettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _currencySettingsGetId,
  getLinks: _currencySettingsGetLinks,
  attach: _currencySettingsAttach,
  version: '3.1.0+1',
);

int _currencySettingsEstimateSize(
  CurrencySettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.localCurrency.length * 3;
  bytesCount += 3 + object.referenceCurrency.length * 3;
  return bytesCount;
}

void _currencySettingsSerialize(
  CurrencySettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isMultiCurrencyEnabled);
  writer.writeString(offsets[1], object.localCurrency);
  writer.writeString(offsets[2], object.referenceCurrency);
}

CurrencySettings _currencySettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CurrencySettings();
  object.id = id;
  object.isMultiCurrencyEnabled = reader.readBool(offsets[0]);
  object.localCurrency = reader.readString(offsets[1]);
  object.referenceCurrency = reader.readString(offsets[2]);
  return object;
}

P _currencySettingsDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _currencySettingsGetId(CurrencySettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _currencySettingsGetLinks(CurrencySettings object) {
  return [];
}

void _currencySettingsAttach(
    IsarCollection<dynamic> col, Id id, CurrencySettings object) {
  object.id = id;
}

extension CurrencySettingsQueryWhereSort
    on QueryBuilder<CurrencySettings, CurrencySettings, QWhere> {
  QueryBuilder<CurrencySettings, CurrencySettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CurrencySettingsQueryWhere
    on QueryBuilder<CurrencySettings, CurrencySettings, QWhereClause> {
  QueryBuilder<CurrencySettings, CurrencySettings, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CurrencySettingsQueryFilter
    on QueryBuilder<CurrencySettings, CurrencySettings, QFilterCondition> {
  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      isMultiCurrencyEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isMultiCurrencyEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      localCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'referenceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'referenceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'referenceCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'referenceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'referenceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'referenceCurrency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'referenceCurrency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceCurrency',
        value: '',
      ));
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterFilterCondition>
      referenceCurrencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referenceCurrency',
        value: '',
      ));
    });
  }
}

extension CurrencySettingsQueryObject
    on QueryBuilder<CurrencySettings, CurrencySettings, QFilterCondition> {}

extension CurrencySettingsQueryLinks
    on QueryBuilder<CurrencySettings, CurrencySettings, QFilterCondition> {}

extension CurrencySettingsQuerySortBy
    on QueryBuilder<CurrencySettings, CurrencySettings, QSortBy> {
  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      sortByIsMultiCurrencyEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMultiCurrencyEnabled', Sort.asc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      sortByIsMultiCurrencyEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMultiCurrencyEnabled', Sort.desc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      sortByLocalCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localCurrency', Sort.asc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      sortByLocalCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localCurrency', Sort.desc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      sortByReferenceCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceCurrency', Sort.asc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      sortByReferenceCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceCurrency', Sort.desc);
    });
  }
}

extension CurrencySettingsQuerySortThenBy
    on QueryBuilder<CurrencySettings, CurrencySettings, QSortThenBy> {
  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      thenByIsMultiCurrencyEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMultiCurrencyEnabled', Sort.asc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      thenByIsMultiCurrencyEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMultiCurrencyEnabled', Sort.desc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      thenByLocalCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localCurrency', Sort.asc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      thenByLocalCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localCurrency', Sort.desc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      thenByReferenceCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceCurrency', Sort.asc);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QAfterSortBy>
      thenByReferenceCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceCurrency', Sort.desc);
    });
  }
}

extension CurrencySettingsQueryWhereDistinct
    on QueryBuilder<CurrencySettings, CurrencySettings, QDistinct> {
  QueryBuilder<CurrencySettings, CurrencySettings, QDistinct>
      distinctByIsMultiCurrencyEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMultiCurrencyEnabled');
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QDistinct>
      distinctByLocalCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localCurrency',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CurrencySettings, CurrencySettings, QDistinct>
      distinctByReferenceCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceCurrency',
          caseSensitive: caseSensitive);
    });
  }
}

extension CurrencySettingsQueryProperty
    on QueryBuilder<CurrencySettings, CurrencySettings, QQueryProperty> {
  QueryBuilder<CurrencySettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CurrencySettings, bool, QQueryOperations>
      isMultiCurrencyEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMultiCurrencyEnabled');
    });
  }

  QueryBuilder<CurrencySettings, String, QQueryOperations>
      localCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localCurrency');
    });
  }

  QueryBuilder<CurrencySettings, String, QQueryOperations>
      referenceCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceCurrency');
    });
  }
}
