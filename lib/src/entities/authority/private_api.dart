import 'dart:convert';
import 'dart:io';

import 'package:iop_sdk/authority.dart';
import 'package:iop_sdk/crypto.dart';
import 'package:iop_sdk/entities.dart';
import 'package:iop_sdk/ssi.dart';
import 'package:iop_sdk/utils.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:optional/optional.dart';

part 'private_api.g.dart';

class AuthorityPrivateApi extends Api {
  AuthorityPrivateApi(ApiConfig config) : super(config);

  Future<List<RequestEntry>> listRequests(PrivateKey withPrivateKey) async {
    final resp = await getAuth('/requests', withPrivateKey);
    if (resp.statusCode == HttpStatus.ok) {
      return ListRequestsResponse.fromJson(json.decode(resp.body)).requests;
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<Optional<dynamic>> getPrivateBlob(
      ContentId contentId, PrivateKey withPrivateKey) async {
    final resp =
        await getAuth('/private-blob/${contentId.value}', withPrivateKey);
    if (resp.statusCode == HttpStatus.ok) {
      return Optional.of(resp.body);
    } else if (resp.statusCode == HttpStatus.notFound) {
      return Optional.empty();
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<void> approveRequest(
    CapabilityLink capabilityLink,
    Signed<WitnessStatement> signedWitnessStatement,
    PrivateKey withPrivateKey,
  ) async {
    final content = signedWitnessStatement.toJson();
    final resp = await postAuth(
      '/requests/${capabilityLink.value}/approve',
      content,
      withPrivateKey,
    );

    if (resp.statusCode != HttpStatus.ok) {
      return Future.error(HttpResponseError(resp.statusCode, resp.body));
    }
  }

  Future<void> rejectRequest(
    CapabilityLink capabilityLink,
    String rejectionReason,
    PrivateKey withPrivateKey,
  ) async {
    final content = {'rejectionReason': rejectionReason};
    final resp = await postAuth(
      '/requests/${capabilityLink.value}/reject',
      content,
      withPrivateKey,
    );

    if (resp.statusCode != HttpStatus.ok) {
      return Future.error(HttpResponseError(resp.statusCode, resp.body));
    }
  }
}

@JsonSerializable(explicitToJson: true)
class ListRequestsResponse {
  final List<RequestEntry> requests;

  ListRequestsResponse(this.requests);

  factory ListRequestsResponse.fromJson(Map<String, dynamic> json) =>
      _$ListRequestsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListRequestsResponseToJson(this);
}
