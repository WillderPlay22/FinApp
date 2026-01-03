// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_movement.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRecurringMovementCollection on Isar {
  IsarCollection<RecurringMovement> get recurringMovements => this.collection();
}

const RecurringMovementSchema = CollectionSchema(
  name: r'RecurringMovement',
  id: 9080100086134001108,
  properties: {
    r'accumulatedAmount': PropertySchema(
      id: 0,
      name: r'accumulatedAmount',
      type: IsarType.double,
    ),
    r'frequency': PropertySchema(
      id: 1,
      name: r'frequency',
      type: IsarType.string,
      enumMap: _RecurringMovementfrequencyEnumValueMap,
    ),
    r'isVariableDaily': PropertySchema(
      id: 2,
      name: r'isVariableDaily',
      type: IsarType.bool,
    ),
    r'nextPaymentDate': PropertySchema(
      id: 3,
      name: r'nextPaymentDate',
      type: IsarType.dateTime,
    ),
    r'paymentAmounts': PropertySchema(
      id: 4,
      name: r'paymentAmounts',
      type: IsarType.doubleList,
    ),
    r'paymentDays': PropertySchema(
      id: 5,
      name: r'paymentDays',
      type: IsarType.longList,
    ),
    r'remainingInstallments': PropertySchema(
      id: 6,
      name: r'remainingInstallments',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 7,
      name: r'title',
      type: IsarType.string,
    ),
    r'totalEntries': PropertySchema(
      id: 8,
      name: r'totalEntries',
      type: IsarType.long,
    ),
    r'type': PropertySchema(
      id: 9,
      name: r'type',
      type: IsarType.string,
      enumMap: _RecurringMovementtypeEnumValueMap,
    )
  },
  estimateSize: _recurringMovementEstimateSize,
  serialize: _recurringMovementSerialize,
  deserialize: _recurringMovementDeserialize,
  deserializeProp: _recurringMovementDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _recurringMovementGetId,
  getLinks: _recurringMovementGetLinks,
  attach: _recurringMovementAttach,
  version: '3.1.0+1',
);

int _recurringMovementEstimateSize(
  RecurringMovement object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.frequency.name.length * 3;
  {
    final value = object.paymentAmounts;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.paymentDays;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _recurringMovementSerialize(
  RecurringMovement object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.accumulatedAmount);
  writer.writeString(offsets[1], object.frequency.name);
  writer.writeBool(offsets[2], object.isVariableDaily);
  writer.writeDateTime(offsets[3], object.nextPaymentDate);
  writer.writeDoubleList(offsets[4], object.paymentAmounts);
  writer.writeLongList(offsets[5], object.paymentDays);
  writer.writeLong(offsets[6], object.remainingInstallments);
  writer.writeString(offsets[7], object.title);
  writer.writeLong(offsets[8], object.totalEntries);
  writer.writeString(offsets[9], object.type.name);
}

RecurringMovement _recurringMovementDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RecurringMovement();
  object.accumulatedAmount = reader.readDouble(offsets[0]);
  object.frequency = _RecurringMovementfrequencyValueEnumMap[
          reader.readStringOrNull(offsets[1])] ??
      Frequency.none;
  object.id = id;
  object.isVariableDaily = reader.readBool(offsets[2]);
  object.nextPaymentDate = reader.readDateTime(offsets[3]);
  object.paymentAmounts = reader.readDoubleList(offsets[4]);
  object.paymentDays = reader.readLongList(offsets[5]);
  object.remainingInstallments = reader.readLongOrNull(offsets[6]);
  object.title = reader.readString(offsets[7]);
  object.totalEntries = reader.readLong(offsets[8]);
  object.type =
      _RecurringMovementtypeValueEnumMap[reader.readStringOrNull(offsets[9])] ??
          TransactionType.income;
  return object;
}

P _recurringMovementDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (_RecurringMovementfrequencyValueEnumMap[
              reader.readStringOrNull(offset)] ??
          Frequency.none) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDoubleList(offset)) as P;
    case 5:
      return (reader.readLongList(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (_RecurringMovementtypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          TransactionType.income) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RecurringMovementfrequencyEnumValueMap = {
  r'none': r'none',
  r'daily': r'daily',
  r'weekly': r'weekly',
  r'biweekly': r'biweekly',
  r'monthly': r'monthly',
  r'yearly': r'yearly',
};
const _RecurringMovementfrequencyValueEnumMap = {
  r'none': Frequency.none,
  r'daily': Frequency.daily,
  r'weekly': Frequency.weekly,
  r'biweekly': Frequency.biweekly,
  r'monthly': Frequency.monthly,
  r'yearly': Frequency.yearly,
};
const _RecurringMovementtypeEnumValueMap = {
  r'income': r'income',
  r'expense': r'expense',
};
const _RecurringMovementtypeValueEnumMap = {
  r'income': TransactionType.income,
  r'expense': TransactionType.expense,
};

Id _recurringMovementGetId(RecurringMovement object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _recurringMovementGetLinks(
    RecurringMovement object) {
  return [];
}

void _recurringMovementAttach(
    IsarCollection<dynamic> col, Id id, RecurringMovement object) {
  object.id = id;
}

extension RecurringMovementQueryWhereSort
    on QueryBuilder<RecurringMovement, RecurringMovement, QWhere> {
  QueryBuilder<RecurringMovement, RecurringMovement, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RecurringMovementQueryWhere
    on QueryBuilder<RecurringMovement, RecurringMovement, QWhereClause> {
  QueryBuilder<RecurringMovement, RecurringMovement, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterWhereClause>
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

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterWhereClause>
      idBetween(
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

extension RecurringMovementQueryFilter
    on QueryBuilder<RecurringMovement, RecurringMovement, QFilterCondition> {
  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      accumulatedAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accumulatedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      accumulatedAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accumulatedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      accumulatedAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accumulatedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      accumulatedAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accumulatedAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyEqualTo(
    Frequency value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyGreaterThan(
    Frequency value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyLessThan(
    Frequency value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyBetween(
    Frequency lower,
    Frequency upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'frequency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'frequency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'frequency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequency',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      frequencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'frequency',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
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

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
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

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
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

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      isVariableDailyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isVariableDaily',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      nextPaymentDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextPaymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      nextPaymentDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextPaymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      nextPaymentDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextPaymentDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      nextPaymentDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextPaymentDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentAmounts',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentAmounts',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentAmounts',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentAmounts',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentAmounts',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentAmounts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentAmounts',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentAmounts',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentAmounts',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentAmounts',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentAmounts',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentAmountsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentAmounts',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentDays',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentDays',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentDays',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentDays',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentDays',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentDays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentDays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentDays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentDays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentDays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      paymentDaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'paymentDays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      remainingInstallmentsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remainingInstallments',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      remainingInstallmentsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remainingInstallments',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      remainingInstallmentsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingInstallments',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      remainingInstallmentsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingInstallments',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      remainingInstallmentsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingInstallments',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      remainingInstallmentsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingInstallments',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      totalEntriesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalEntries',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      totalEntriesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalEntries',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      totalEntriesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalEntries',
        value: value,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      totalEntriesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalEntries',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeEqualTo(
    TransactionType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeGreaterThan(
    TransactionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeLessThan(
    TransactionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeBetween(
    TransactionType lower,
    TransactionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension RecurringMovementQueryObject
    on QueryBuilder<RecurringMovement, RecurringMovement, QFilterCondition> {}

extension RecurringMovementQueryLinks
    on QueryBuilder<RecurringMovement, RecurringMovement, QFilterCondition> {}

extension RecurringMovementQuerySortBy
    on QueryBuilder<RecurringMovement, RecurringMovement, QSortBy> {
  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByAccumulatedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accumulatedAmount', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByAccumulatedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accumulatedAmount', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByIsVariableDaily() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVariableDaily', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByIsVariableDailyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVariableDaily', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByNextPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextPaymentDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByNextPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextPaymentDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByRemainingInstallments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingInstallments', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByRemainingInstallmentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingInstallments', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByTotalEntries() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEntries', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByTotalEntriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEntries', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension RecurringMovementQuerySortThenBy
    on QueryBuilder<RecurringMovement, RecurringMovement, QSortThenBy> {
  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByAccumulatedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accumulatedAmount', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByAccumulatedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accumulatedAmount', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByIsVariableDaily() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVariableDaily', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByIsVariableDailyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVariableDaily', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByNextPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextPaymentDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByNextPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextPaymentDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByRemainingInstallments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingInstallments', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByRemainingInstallmentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingInstallments', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByTotalEntries() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEntries', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByTotalEntriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEntries', Sort.desc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension RecurringMovementQueryWhereDistinct
    on QueryBuilder<RecurringMovement, RecurringMovement, QDistinct> {
  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct>
      distinctByAccumulatedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accumulatedAmount');
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct>
      distinctByFrequency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct>
      distinctByIsVariableDaily() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isVariableDaily');
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct>
      distinctByNextPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextPaymentDate');
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct>
      distinctByPaymentAmounts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentAmounts');
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct>
      distinctByPaymentDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentDays');
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct>
      distinctByRemainingInstallments() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingInstallments');
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct>
      distinctByTotalEntries() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalEntries');
    });
  }

  QueryBuilder<RecurringMovement, RecurringMovement, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension RecurringMovementQueryProperty
    on QueryBuilder<RecurringMovement, RecurringMovement, QQueryProperty> {
  QueryBuilder<RecurringMovement, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RecurringMovement, double, QQueryOperations>
      accumulatedAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accumulatedAmount');
    });
  }

  QueryBuilder<RecurringMovement, Frequency, QQueryOperations>
      frequencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequency');
    });
  }

  QueryBuilder<RecurringMovement, bool, QQueryOperations>
      isVariableDailyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isVariableDaily');
    });
  }

  QueryBuilder<RecurringMovement, DateTime, QQueryOperations>
      nextPaymentDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextPaymentDate');
    });
  }

  QueryBuilder<RecurringMovement, List<double>?, QQueryOperations>
      paymentAmountsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentAmounts');
    });
  }

  QueryBuilder<RecurringMovement, List<int>?, QQueryOperations>
      paymentDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentDays');
    });
  }

  QueryBuilder<RecurringMovement, int?, QQueryOperations>
      remainingInstallmentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingInstallments');
    });
  }

  QueryBuilder<RecurringMovement, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<RecurringMovement, int, QQueryOperations>
      totalEntriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalEntries');
    });
  }

  QueryBuilder<RecurringMovement, TransactionType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
