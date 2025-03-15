import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
