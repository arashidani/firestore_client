import 'package:freezed_annotation/freezed_annotation.dart';

class IsoDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const IsoDateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    return DateTime.tryParse(json);
  }

  @override
  String? toJson(DateTime? date) {
    return date?.toIso8601String();
  }
}