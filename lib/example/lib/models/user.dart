import 'package:firestore_client/firestore_client.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  factory User({
    required String id,
    required String name,
    @TimeStampConverter() required DateTime? createdAt,
    @TimeStampConverter() required DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
