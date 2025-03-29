// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: const TimeStampConverter().fromJson(json['createdAt']),
      updatedAt: const TimeStampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': const TimeStampConverter().toJson(instance.createdAt),
      'updatedAt': const TimeStampConverter().toJson(instance.updatedAt),
    };
