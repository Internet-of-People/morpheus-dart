// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListRequestsResponse _$ListRequestsResponseFromJson(Map<String, dynamic> json) {
  return ListRequestsResponse(
    (json['requests'] as List)
        ?.map((e) =>
            e == null ? null : RequestEntry.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$ListRequestsResponseToJson(
        ListRequestsResponse instance) =>
    <String, dynamic>{
      'requests': instance.requests?.map((e) => e?.toJson())?.toList(),
    };
