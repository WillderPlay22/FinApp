// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFinancialTransactionCollection on Isar {
  IsarCollection<FinancialTransaction> get financialTransactions =>
      this.collection();
}

const FinancialTransactionSchema = CollectionSchema(
  name: r'FinancialTransaction',
  id: -6806526985602844534,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'amountInLocalCurrency': PropertySchema(
      id: 1,
      name: r'amountInLocalCurrency',
      type: IsarType.double,
    ),
    r'amountInReferenceCurrency': PropertySchema(
      id: 2,
      name: r'amountInReferenceCurrency',
      type: IsarType.double,
    ),
    r'categoryIconCode': PropertySchema(
      id: 3,
      name: r'categoryIconCode',
      type: IsarType.long,
    ),
    r'categoryName': PropertySchema(
      id: 4,
      name: r'categoryName',
      type: IsarType.string,
    ),
    r'colorValue': PropertySchema(
      id: 5,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'currencyCode': PropertySchema(
      id: 6,
      name: r'currencyCode',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 7,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'exchangeRateAtTime': PropertySchema(
      id: 8,
      name: r'exchangeRateAtTime',
      type: IsarType.double,
    ),
    r'fixedLocalPortion': PropertySchema(
      id: 9,
      name: r'fixedLocalPortion',
      type: IsarType.double,
    ),
    r'fixedReferencePortion': PropertySchema(
      id: 10,
      name: r'fixedReferencePortion',
      type: IsarType.double,
    ),
    r'isRecurring': PropertySchema(
      id: 11,
      name: r'isRecurring',
      type: IsarType.bool,
    ),
    r'note': PropertySchema(
      id: 12,
      name: r'note',
      type: IsarType.string,
    ),
    r'parentRecurringId': PropertySchema(
      id: 13,
      name: r'parentRecurringId',
      type: IsarType.long,
    ),
    r'paymentMode': PropertySchema(
      id: 14,
      name: r'paymentMode',
      type: IsarType.string,
      enumMap: _FinancialTransactionpaymentModeEnumValueMap,
    ),
    r'type': PropertySchema(
      id: 15,
      name: r'type',
      type: IsarType.string,
      enumMap: _FinancialTransactiontypeEnumValueMap,
    )
  },
  estimateSize: _financialTransactionEstimateSize,
  serialize: _financialTransactionSerialize,
  deserialize: _financialTransactionDeserialize,
  deserializeProp: _financialTransactionDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'parentRecurringId': IndexSchema(
      id: 6127313349986115284,
      name: r'parentRecurringId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'parentRecurringId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'relatedExpense': LinkSchema(
      id: 1317223007959203392,
      name: r'relatedExpense',
      target: r'Expense',
      single: true,
    ),
    r'relatedDebt': LinkSchema(
      id: 8523989151007108499,
      name: r'relatedDebt',
      target: r'Debt',
      single: true,
    ),
    r'relatedSaving': LinkSchema(
      id: -3642736202653662871,
      name: r'relatedSaving',
      target: r'Saving',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _financialTransactionGetId,
  getLinks: _financialTransactionGetLinks,
  attach: _financialTransactionAttach,
  version: '3.1.0+1',
);

int _financialTransactionEstimateSize(
  FinancialTransaction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.categoryName.length * 3;
  {
    final value = object.currencyCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.note.length * 3;
  {
    final value = object.paymentMode;
    if (value != null) {
      bytesCount += 3 + value.name.length * 3;
    }
  }
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _financialTransactionSerialize(
  FinancialTransaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeDouble(offsets[1], object.amountInLocalCurrency);
  writer.writeDouble(offsets[2], object.amountInReferenceCurrency);
  writer.writeLong(offsets[3], object.categoryIconCode);
  writer.writeString(offsets[4], object.categoryName);
  writer.writeLong(offsets[5], object.colorValue);
  writer.writeString(offsets[6], object.currencyCode);
  writer.writeDateTime(offsets[7], object.date);
  writer.writeDouble(offsets[8], object.exchangeRateAtTime);
  writer.writeDouble(offsets[9], object.fixedLocalPortion);
  writer.writeDouble(offsets[10], object.fixedReferencePortion);
  writer.writeBool(offsets[11], object.isRecurring);
  writer.writeString(offsets[12], object.note);
  writer.writeLong(offsets[13], object.parentRecurringId);
  writer.writeString(offsets[14], object.paymentMode?.name);
  writer.writeString(offsets[15], object.type.name);
}

FinancialTransaction _financialTransactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FinancialTransaction();
  object.amount = reader.readDouble(offsets[0]);
  object.amountInLocalCurrency = reader.readDoubleOrNull(offsets[1]);
  object.amountInReferenceCurrency = reader.readDoubleOrNull(offsets[2]);
  object.categoryIconCode = reader.readLong(offsets[3]);
  object.categoryName = reader.readString(offsets[4]);
  object.colorValue = reader.readLong(offsets[5]);
  object.currencyCode = reader.readStringOrNull(offsets[6]);
  object.date = reader.readDateTime(offsets[7]);
  object.exchangeRateAtTime = reader.readDoubleOrNull(offsets[8]);
  object.fixedLocalPortion = reader.readDoubleOrNull(offsets[9]);
  object.fixedReferencePortion = reader.readDoubleOrNull(offsets[10]);
  object.id = id;
  object.isRecurring = reader.readBool(offsets[11]);
  object.note = reader.readString(offsets[12]);
  object.parentRecurringId = reader.readLongOrNull(offsets[13]);
  object.paymentMode = _FinancialTransactionpaymentModeValueEnumMap[
      reader.readStringOrNull(offsets[14])];
  object.type = _FinancialTransactiontypeValueEnumMap[
          reader.readStringOrNull(offsets[15])] ??
      TransactionType.income;
  return object;
}

P _financialTransactionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (_FinancialTransactionpaymentModeValueEnumMap[
          reader.readStringOrNull(offset)]) as P;
    case 15:
      return (_FinancialTransactiontypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          TransactionType.income) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _FinancialTransactionpaymentModeEnumValueMap = {
  r'singleCurrency': r'singleCurrency',
  r'allReference': r'allReference',
  r'allLocal': r'allLocal',
  r'mixed': r'mixed',
};
const _FinancialTransactionpaymentModeValueEnumMap = {
  r'singleCurrency': PaymentMode.singleCurrency,
  r'allReference': PaymentMode.allReference,
  r'allLocal': PaymentMode.allLocal,
  r'mixed': PaymentMode.mixed,
};
const _FinancialTransactiontypeEnumValueMap = {
  r'income': r'income',
  r'expense': r'expense',
  r'saving': r'saving',
};
const _FinancialTransactiontypeValueEnumMap = {
  r'income': TransactionType.income,
  r'expense': TransactionType.expense,
  r'saving': TransactionType.saving,
};

Id _financialTransactionGetId(FinancialTransaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _financialTransactionGetLinks(
    FinancialTransaction object) {
  return [object.relatedExpense, object.relatedDebt, object.relatedSaving];
}

void _financialTransactionAttach(
    IsarCollection<dynamic> col, Id id, FinancialTransaction object) {
  object.id = id;
  object.relatedExpense
      .attach(col, col.isar.collection<Expense>(), r'relatedExpense', id);
  object.relatedDebt
      .attach(col, col.isar.collection<Debt>(), r'relatedDebt', id);
  object.relatedSaving
      .attach(col, col.isar.collection<Saving>(), r'relatedSaving', id);
}

extension FinancialTransactionQueryWhereSort
    on QueryBuilder<FinancialTransaction, FinancialTransaction, QWhere> {
  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhere>
      anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhere>
      anyParentRecurringId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'parentRecurringId'),
      );
    });
  }
}

extension FinancialTransactionQueryWhere
    on QueryBuilder<FinancialTransaction, FinancialTransaction, QWhereClause> {
  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
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

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
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

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      dateEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      parentRecurringIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'parentRecurringId',
        value: [null],
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      parentRecurringIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'parentRecurringId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      parentRecurringIdEqualTo(int? parentRecurringId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'parentRecurringId',
        value: [parentRecurringId],
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      parentRecurringIdNotEqualTo(int? parentRecurringId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'parentRecurringId',
              lower: [],
              upper: [parentRecurringId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'parentRecurringId',
              lower: [parentRecurringId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'parentRecurringId',
              lower: [parentRecurringId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'parentRecurringId',
              lower: [],
              upper: [parentRecurringId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      parentRecurringIdGreaterThan(
    int? parentRecurringId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'parentRecurringId',
        lower: [parentRecurringId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      parentRecurringIdLessThan(
    int? parentRecurringId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'parentRecurringId',
        lower: [],
        upper: [parentRecurringId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterWhereClause>
      parentRecurringIdBetween(
    int? lowerParentRecurringId,
    int? upperParentRecurringId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'parentRecurringId',
        lower: [lowerParentRecurringId],
        includeLower: includeLower,
        upper: [upperParentRecurringId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FinancialTransactionQueryFilter on QueryBuilder<FinancialTransaction,
    FinancialTransaction, QFilterCondition> {
  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInLocalCurrencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amountInLocalCurrency',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInLocalCurrencyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amountInLocalCurrency',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInLocalCurrencyEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountInLocalCurrency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInLocalCurrencyGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountInLocalCurrency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInLocalCurrencyLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountInLocalCurrency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInLocalCurrencyBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountInLocalCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInReferenceCurrencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amountInReferenceCurrency',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInReferenceCurrencyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amountInReferenceCurrency',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInReferenceCurrencyEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountInReferenceCurrency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInReferenceCurrencyGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountInReferenceCurrency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInReferenceCurrencyLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountInReferenceCurrency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> amountInReferenceCurrencyBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountInReferenceCurrency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryIconCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryIconCode',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryIconCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryIconCode',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryIconCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryIconCode',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryIconCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryIconCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      categoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      categoryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> categoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> colorValueGreaterThan(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> colorValueLessThan(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> colorValueBetween(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currencyCode',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currencyCode',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeEqualTo(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeGreaterThan(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeLessThan(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeBetween(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeStartsWith(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeEndsWith(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      currencyCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currencyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      currencyCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currencyCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currencyCode',
        value: '',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> currencyCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currencyCode',
        value: '',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> exchangeRateAtTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'exchangeRateAtTime',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> exchangeRateAtTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'exchangeRateAtTime',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> exchangeRateAtTimeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exchangeRateAtTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> exchangeRateAtTimeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exchangeRateAtTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> exchangeRateAtTimeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exchangeRateAtTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> exchangeRateAtTimeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exchangeRateAtTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedLocalPortionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fixedLocalPortion',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedLocalPortionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fixedLocalPortion',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedLocalPortionEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fixedLocalPortion',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedLocalPortionGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fixedLocalPortion',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedLocalPortionLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fixedLocalPortion',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedLocalPortionBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fixedLocalPortion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedReferencePortionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fixedReferencePortion',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedReferencePortionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fixedReferencePortion',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedReferencePortionEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fixedReferencePortion',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedReferencePortionGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fixedReferencePortion',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedReferencePortionLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fixedReferencePortion',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> fixedReferencePortionBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fixedReferencePortion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> isRecurringEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRecurring',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> noteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> noteGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> noteLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> noteBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> parentRecurringIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentRecurringId',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> parentRecurringIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentRecurringId',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> parentRecurringIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentRecurringId',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> parentRecurringIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentRecurringId',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> parentRecurringIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentRecurringId',
        value: value,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> parentRecurringIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentRecurringId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentMode',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentMode',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeEqualTo(
    PaymentMode? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeGreaterThan(
    PaymentMode? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeLessThan(
    PaymentMode? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeBetween(
    PaymentMode? lower,
    PaymentMode? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      paymentModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      paymentModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentMode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentMode',
        value: '',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> paymentModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentMode',
        value: '',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> typeEqualTo(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> typeGreaterThan(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> typeLessThan(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> typeBetween(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> typeStartsWith(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> typeEndsWith(
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

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
          QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension FinancialTransactionQueryObject on QueryBuilder<FinancialTransaction,
    FinancialTransaction, QFilterCondition> {}

extension FinancialTransactionQueryLinks on QueryBuilder<FinancialTransaction,
    FinancialTransaction, QFilterCondition> {
  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> relatedExpense(FilterQuery<Expense> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'relatedExpense');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> relatedExpenseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'relatedExpense', 0, true, 0, true);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> relatedDebt(FilterQuery<Debt> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'relatedDebt');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> relatedDebtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'relatedDebt', 0, true, 0, true);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> relatedSaving(FilterQuery<Saving> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'relatedSaving');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction,
      QAfterFilterCondition> relatedSavingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'relatedSaving', 0, true, 0, true);
    });
  }
}

extension FinancialTransactionQuerySortBy
    on QueryBuilder<FinancialTransaction, FinancialTransaction, QSortBy> {
  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByAmountInLocalCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountInLocalCurrency', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByAmountInLocalCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountInLocalCurrency', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByAmountInReferenceCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountInReferenceCurrency', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByAmountInReferenceCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountInReferenceCurrency', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByCategoryIconCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryIconCode', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByCategoryIconCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryIconCode', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByCurrencyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByCurrencyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByExchangeRateAtTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRateAtTime', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByExchangeRateAtTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRateAtTime', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByFixedLocalPortion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedLocalPortion', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByFixedLocalPortionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedLocalPortion', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByFixedReferencePortion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedReferencePortion', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByFixedReferencePortionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedReferencePortion', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByIsRecurring() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecurring', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByIsRecurringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecurring', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByParentRecurringId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentRecurringId', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByParentRecurringIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentRecurringId', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByPaymentMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMode', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByPaymentModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMode', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension FinancialTransactionQuerySortThenBy
    on QueryBuilder<FinancialTransaction, FinancialTransaction, QSortThenBy> {
  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByAmountInLocalCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountInLocalCurrency', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByAmountInLocalCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountInLocalCurrency', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByAmountInReferenceCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountInReferenceCurrency', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByAmountInReferenceCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountInReferenceCurrency', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByCategoryIconCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryIconCode', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByCategoryIconCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryIconCode', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByCurrencyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByCurrencyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencyCode', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByExchangeRateAtTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRateAtTime', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByExchangeRateAtTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeRateAtTime', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByFixedLocalPortion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedLocalPortion', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByFixedLocalPortionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedLocalPortion', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByFixedReferencePortion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedReferencePortion', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByFixedReferencePortionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fixedReferencePortion', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByIsRecurring() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecurring', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByIsRecurringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRecurring', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByParentRecurringId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentRecurringId', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByParentRecurringIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentRecurringId', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByPaymentMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMode', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByPaymentModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMode', Sort.desc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension FinancialTransactionQueryWhereDistinct
    on QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct> {
  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByAmountInLocalCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountInLocalCurrency');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByAmountInReferenceCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountInReferenceCurrency');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByCategoryIconCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryIconCode');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByCategoryName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByCurrencyCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currencyCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByExchangeRateAtTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exchangeRateAtTime');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByFixedLocalPortion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fixedLocalPortion');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByFixedReferencePortion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fixedReferencePortion');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByIsRecurring() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRecurring');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByNote({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByParentRecurringId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentRecurringId');
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByPaymentMode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentMode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FinancialTransaction, FinancialTransaction, QDistinct>
      distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension FinancialTransactionQueryProperty on QueryBuilder<
    FinancialTransaction, FinancialTransaction, QQueryProperty> {
  QueryBuilder<FinancialTransaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FinancialTransaction, double, QQueryOperations>
      amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<FinancialTransaction, double?, QQueryOperations>
      amountInLocalCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountInLocalCurrency');
    });
  }

  QueryBuilder<FinancialTransaction, double?, QQueryOperations>
      amountInReferenceCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountInReferenceCurrency');
    });
  }

  QueryBuilder<FinancialTransaction, int, QQueryOperations>
      categoryIconCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryIconCode');
    });
  }

  QueryBuilder<FinancialTransaction, String, QQueryOperations>
      categoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryName');
    });
  }

  QueryBuilder<FinancialTransaction, int, QQueryOperations>
      colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<FinancialTransaction, String?, QQueryOperations>
      currencyCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currencyCode');
    });
  }

  QueryBuilder<FinancialTransaction, DateTime, QQueryOperations>
      dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<FinancialTransaction, double?, QQueryOperations>
      exchangeRateAtTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exchangeRateAtTime');
    });
  }

  QueryBuilder<FinancialTransaction, double?, QQueryOperations>
      fixedLocalPortionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fixedLocalPortion');
    });
  }

  QueryBuilder<FinancialTransaction, double?, QQueryOperations>
      fixedReferencePortionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fixedReferencePortion');
    });
  }

  QueryBuilder<FinancialTransaction, bool, QQueryOperations>
      isRecurringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRecurring');
    });
  }

  QueryBuilder<FinancialTransaction, String, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<FinancialTransaction, int?, QQueryOperations>
      parentRecurringIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentRecurringId');
    });
  }

  QueryBuilder<FinancialTransaction, PaymentMode?, QQueryOperations>
      paymentModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMode');
    });
  }

  QueryBuilder<FinancialTransaction, TransactionType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
