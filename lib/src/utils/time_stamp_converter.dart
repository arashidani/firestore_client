import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// FirestoreのTimestamp型とDartのDateTime型を相互変換するためのコンバータです。
/// Freezedやjson_serializable の @JsonKeyで使用することを想定しています。
///
/// 例:
/// ```dart
/// @TimeStampConverter()
/// final DateTime? createdAt;
/// ```
class TimeStampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimeStampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    }
    return null; // Timestamp でない場合は null を返す
  }

  @override
  dynamic toJson(DateTime? date) {
    return date != null ? Timestamp.fromDate(date) : null;
  }
}
