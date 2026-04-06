// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSavingCollection on Isar {
  IsarCollection<Saving> get savings => this.collection();
}

const SavingSchema = CollectionSchema(
  name: r'Saving',
  id: -3813762252173960950,
  properties: {
    r'colorValue': PropertySchema(
      id: 0,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'currencyCode': PropertySchema(
      id: 1,
      name: r'currencyCode',
      type: IsarType.string,
    ),
    r'currentAmount': PropertySchema(
      id: 2,
      name: r'currentAmount',
      type: IsarType.double,
    ),
    r'fixedAmount': PropertySchema(
      id: 3,
      name: r'fixedAmount',
      type: IsarType.double,
    ),
    r'iconCode': PropertySchema(
      id: 4,
      name: r'iconCode',
      type: IsarType.long,
    ),
    r'method': PropertySchema(
      id: 5,
      name: r'method',
      type: IsarType.byte,
      enumMap: _SavingmethodEnumValueMap,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'percentage': PropertySchema(
      id: 7,
      name: r'percentage',
      type: IsarType.double,
    ),
    r'targetAmount': PropertySchema(
      id: 8,
      name: r'targetAmount',
      type: IsarType.double,
    ),
    r'type': PropertySchema(
      id: 9,
      name: r'type',
      type: IsarType.byte,
      enumMap: _SavingtypeEnumValueMap,
    )
  },
  estimateSize: _savingEstimateSize,
  serialize: _savingSerialize,
  deserialize: _savingDeserialize,
  deserializeProp: _savingDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _savingGetId,
  getLinks: _savingGetLinks,
  attach: _savingAttach,
  version: '3.1.0+1',
);

int _savingEstimateSize(
  Saving object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.currencyCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _savingSerialize(
  Saving object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.colorValue);
  writer.writeString(offsets[1], object.currencyCode);
  writer.writeDouble(offsets[2], object.currentAmount);
  writer.writeDouble(offsets[3], object.fixedAmount);
  writer.writeLong(offsets[4], object.iconCode);
  writer.writeByte(offsets[5], object.method.index);
  writer.writeString(offsets[6], object.name);
  writer.writeDouble(offsets[7], object.percentage);
  writer.writeDouble(offsets[8], object.targetAmount);
  writer.writeByte(offsets[9], object.type.index);
}

Saving _savingDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Saving();
  object.colorValue = reader.readLong(offsets[0]);
  object.currencyCode = reader.readStringOrNull(offsets[1]);
  object.currentAmount = reader.readDouble(offsets[2]);
  object.fixedAmount = reader.readDoubleOrNull(offsets[3]);
  object.iconCode = reader.readLong(offsets[4]);
  object.id = id;
  object.method =
      _SavingmethodValueEnumMap[reader.readByteOrNull(offsets[5])] ??
          SavingMethod.fixed;
  object.name = reader.readString(offsets[6]);
  object.percentage = reader.readDoubleOrNull(offsets[7]);
  object.targetAmount = reader.readDoubleOrNull(offsets[8]);
  object.type = _SavingtypeValueEnumMap[reader.readByteOrNull(offsets[9])] ??
      SavingType.goal;
  return object;
}

P _savingDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (_SavingmethodValueEnumMap[reader.readByteOrNull(offset)] ??
          SavingMethod.fixed) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (_SavingtypeValueEnumMap[reader.readByteOrNull(offset)] ??
          SavingType.goal) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SavingmethodEnumValueMap = {
  'fixed': 0,
  'percentage': 1,
};
const _SavingmethodValueEnumMap = {
  0: SavingMethod.fixed,
  1: SavingMethod.percentage,
};
const _SavingtypeEnumValueMap = {
  'goal': 0,
  'fund': 1,
};
const _SavingtypeValueEnumMap = {
  0: SavingType.goal,
  1: SavingType.fund,
};

Id _savingGetId(Saving object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _savingGetLinks(Saving object) {
  return [];
}

void _savingAttach(IsarCollection<dynamic> col, Id id, Saving object) {
  object.id = id;
}

extension SavingQueryWhereSort on QueryBuilder<Saving, Saving, QWhere> {
  QueryBuilder<Saving, Saving, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SavingQueryWhere on QueryBuilder<Saving, Saving, QWhereClause> {
  QueryBuilder<Saving, Saving, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Saving, Saving, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Saving, Saving, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Saving, Saving, QAfterWhereClause> idBetween(
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

extension SavingQueryFilter on QueryBuilder<Saving, Saving, QFilterCondition> {
  QueryBuilder<Saving, Saving, QAfterFilterCondition> colorValueEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> colorValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> colorValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> colorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currencyCode',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currencyCode',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currencyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currencyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currencyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currencyCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currencyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currencyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currencyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currencyCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currencyCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currencyCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currencyCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currentAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currentAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currentAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> currentAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> fixedAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fixedAmount',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> fixedAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fixedAmount',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> fixedAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fixedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> fixedAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fixedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> fixedAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fixedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> fixedAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fixedAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> iconCodeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> iconCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iconCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> iconCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iconCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> iconCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iconCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Saving, Saving, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Saving, Saving, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Saving, Saving, QAfterFilterCondition> methodEqualTo(
      SavingMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> methodGreaterThan(
    SavingMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'method',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> methodLessThan(
    SavingMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'method',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> methodBetween(
    SavingMethod lower,
    SavingMethod upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'method',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> percentageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'percentage',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> percentageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'percentage',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> percentageEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'percentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> percentageGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'percentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> percentageLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'percentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> percentageBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'percentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> targetAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetAmount',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> targetAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetAmount',
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> targetAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> targetAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> targetAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> targetAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> typeEqualTo(
      SavingType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> typeGreaterThan(
    SavingType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> typeLessThan(
    SavingType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Saving, Saving, QAfterFilterCondition> typeBetween(
    SavingType lower,
    SavingType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SavingQueryObject on QueryBuilder<Saving, Saving, QFilterCondition> {}

extension SavingQueryLinks on QueryBuilder<Saving, Saving, QFilterCondition> {}

extension SavingQuerySortBy on QueryBuilder<Saving, Saving, QSortBy> {
  QueryBuilder<Saving, Saving, QAfterSortBy> sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByCurrencyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByCurrencyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByCurrentAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAmount', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByCurrentAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAmount', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByFixedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedAmount', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByFixedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedAmount', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByIconCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCode', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByIconCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCode', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'percentage', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'percentage', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByTargetAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetAmount', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByTargetAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetAmount', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension SavingQuerySortThenBy on QueryBuilder<Saving, Saving, QSortThenBy> {
  QueryBuilder<Saving, Saving, QAfterSortBy> thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByCurrencyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByCurrencyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByCurrentAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAmount', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByCurrentAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAmount', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByFixedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedAmount', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByFixedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedAmount', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByIconCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCode', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByIconCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCode', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'percentage', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'percentage', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByTargetAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetAmount', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByTargetAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetAmount', Sort.desc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Saving, Saving, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension SavingQueryWhereDistinct on QueryBuilder<Saving, Saving, QDistinct> {
  QueryBuilder<Saving, Saving, QDistinct> distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<Saving, Saving, QDistinct> distinctByCurrencyCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currencyCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Saving, Saving, QDistinct> distinctByCurrentAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentAmount');
    });
  }

  QueryBuilder<Saving, Saving, QDistinct> distinctByFixedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fixedAmount');
    });
  }

  QueryBuilder<Saving, Saving, QDistinct> distinctByIconCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconCode');
    });
  }

  QueryBuilder<Saving, Saving, QDistinct> distinctByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'method');
    });
  }

  QueryBuilder<Saving, Saving, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Saving, Saving, QDistinct> distinctByPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'percentage');
    });
  }

  QueryBuilder<Saving, Saving, QDistinct> distinctByTargetAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetAmount');
    });
  }

  QueryBuilder<Saving, Saving, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }
}

extension SavingQueryProperty on QueryBuilder<Saving, Saving, QQueryProperty> {
  QueryBuilder<Saving, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Saving, int, QQueryOperations> colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<Saving, String?, QQueryOperations> currencyCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currencyCode');
    });
  }

  QueryBuilder<Saving, double, QQueryOperations> currentAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentAmount');
    });
  }

  QueryBuilder<Saving, double?, QQueryOperations> fixedAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fixedAmount');
    });
  }

  QueryBuilder<Saving, int, QQueryOperations> iconCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconCode');
    });
  }

  QueryBuilder<Saving, SavingMethod, QQueryOperations> methodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'method');
    });
  }

  QueryBuilder<Saving, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Saving, double?, QQueryOperations> percentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'percentage');
    });
  }

  QueryBuilder<Saving, double?, QQueryOperations> targetAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetAmount');
    });
  }

  QueryBuilder<Saving, SavingType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
