/// Firestore のクエリ条件を表すクラス。
/// 各フィールドに値をセットすることで、Firestore の where 句をチェーン的に適用できます。
class QueryCondition {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  const QueryCondition(
    this.field, {
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// QueryCondition を組み立てるためのビルダー例。
/// 利用例:
/// ```dart
/// final condition = QueryConditionBuilder('age')
///   .isGreaterThan(20)
///   .build();
/// ```
class QueryConditionBuilder {
  final String field;
  dynamic _isEqualTo;
  dynamic _isNotEqualTo;
  dynamic _isLessThan;
  dynamic _isLessThanOrEqualTo;
  dynamic _isGreaterThan;
  dynamic _isGreaterThanOrEqualTo;
  dynamic _arrayContains;
  List<dynamic>? _arrayContainsAny;
  List<dynamic>? _whereIn;
  List<dynamic>? _whereNotIn;
  bool? _isNull;

  QueryConditionBuilder(this.field);

  QueryConditionBuilder equalTo(dynamic value) {
    _isEqualTo = value;
    return this;
  }

  QueryConditionBuilder notEqualTo(dynamic value) {
    _isNotEqualTo = value;
    return this;
  }

  QueryConditionBuilder lessThan(dynamic value) {
    _isLessThan = value;
    return this;
  }

  QueryConditionBuilder lessThanOrEqualTo(dynamic value) {
    _isLessThanOrEqualTo = value;
    return this;
  }

  QueryConditionBuilder greaterThan(dynamic value) {
    _isGreaterThan = value;
    return this;
  }

  QueryConditionBuilder greaterThanOrEqualTo(dynamic value) {
    _isGreaterThanOrEqualTo = value;
    return this;
  }

  QueryConditionBuilder arrayContains(dynamic value) {
    _arrayContains = value;
    return this;
  }

  QueryConditionBuilder arrayContainsAny(List<dynamic> values) {
    _arrayContainsAny = values;
    return this;
  }

  QueryConditionBuilder whereIn(List<dynamic> values) {
    _whereIn = values;
    return this;
  }

  QueryConditionBuilder whereNotIn(List<dynamic> values) {
    _whereNotIn = values;
    return this;
  }

  QueryConditionBuilder isNull(bool value) {
    _isNull = value;
    return this;
  }

  QueryCondition build() {
    return QueryCondition(
      field,
      isEqualTo: _isEqualTo,
      isNotEqualTo: _isNotEqualTo,
      isLessThan: _isLessThan,
      isLessThanOrEqualTo: _isLessThanOrEqualTo,
      isGreaterThan: _isGreaterThan,
      isGreaterThanOrEqualTo: _isGreaterThanOrEqualTo,
      arrayContains: _arrayContains,
      arrayContainsAny: _arrayContainsAny,
      whereIn: _whereIn,
      whereNotIn: _whereNotIn,
      isNull: _isNull,
    );
  }
}
