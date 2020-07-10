import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:morpheus_sdk/src/io.dart';
import 'package:morpheus_sdk/ssi/io.dart';
import 'package:optional/optional.dart';

part 'public_api.g.dart';

class InspectorPublicApi extends Api {
  InspectorPublicApi(ApiConfig config) : super(config);

  Future<List<ContentId>> listScenarios() async {
    final resp = await get('/scenarios');
    if (resp.statusCode == HttpStatus.ok) {
      return ListScenariosResponse.fromJson(json.decode(resp.body)).scenarios;
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<Optional<dynamic>> getPublicBlob(ContentId contentId) async {
    final resp = await get('/blob/${contentId.value}');
    if (resp.statusCode == HttpStatus.ok) {
      return Optional.of(resp.body);
    } else if (resp.statusCode == HttpStatus.notFound) {
      return Optional.empty();
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<ContentId> uploadPresentation(
    Signed<Presentation> presentation,
  ) async {
    final resp = await post('/presentation', presentation.toJson());

    if (resp.statusCode == HttpStatus.accepted) {
      return ContentId.fromJson(json.decode(resp.body));
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }
}

@JsonSerializable(explicitToJson: true)
class ListScenariosResponse {
  final List<ContentId> scenarios;

  ListScenariosResponse(this.scenarios);

  factory ListScenariosResponse.fromJson(Map<String, dynamic> json) =>
      _$ListScenariosResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListScenariosResponseToJson(this);
}