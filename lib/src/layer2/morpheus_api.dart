import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:iop_sdk/crypto.dart';
import 'package:iop_sdk/layer1.dart';
import 'package:iop_sdk/layer2.dart';
import 'package:iop_sdk/network.dart';
import 'package:iop_sdk/ssi.dart';
import 'package:iop_sdk/utils.dart';
import 'package:optional/optional.dart';

class MorpheusApi {
  final Client _client = Client();
  final NetworkConfig _networkConfig;

  MorpheusApi(this._networkConfig);

  Future<BeforeProofHistoryResponse> getBeforeProofHistory(
    ContentId contentId,
  ) async {
    final resp =
        await _layer2ApiGet('/before-proof/${contentId.value}/history');

    if (resp.statusCode == HttpStatus.ok) {
      final body = json.decode(resp.body);
      return BeforeProofHistoryResponse.fromJson(body);
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<bool> beforeProofExists(ContentId contentId, {int height}) async {
    final resp = await _layer2ApiGet(
      _widthHeight('/before-proof/${contentId.value}/exists', height),
    );
    return json.decode(resp.body);
  }

  Future<DidDocument> getDidDocument(DidData did, {int height}) async {
    final resp = await _layer2ApiGet(
      _widthHeight('/did/${did.value}/document', height),
    );

    if (resp.statusCode == HttpStatus.ok) {
      final body = json.decode(resp.body);
      final didData = DidDocumentData.fromJson(body);
      return DidDocument(didData);
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<Optional<bool>> getTxnStatus(String txId) async {
    final resp = await _layer2ApiGet('/txn-status/$txId');

    if (resp.statusCode == HttpStatus.ok) {
      return Optional.of(json.decode(resp.body));
    } else if (resp.statusCode == HttpStatus.notFound) {
      return Optional.empty();
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<String> getLastTxId(DidData did) async {
    final resp = await _layer2ApiGet('/did/${did.value}/transactions/last');

    if (resp.statusCode == HttpStatus.ok) {
      return json.decode(resp.body)['transactionId'];
    } else if (resp.statusCode == HttpStatus.notFound) {
      return null;
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<List<TransactionIdHeight>> getDidTransactionIds(
    DidData did,
    int fromHeight, {
    int untilHeight,
  }) async {
    return _didTransactionIdsQuery(
      false,
      did,
      fromHeight,
      untilHeight: untilHeight,
    );
  }

  Future<List<TransactionIdHeight>> getDidTransactionAttemptIds(
    DidData did,
    int fromHeight, {
    int untilHeight,
  }) async {
    return _didTransactionIdsQuery(
      true,
      did,
      fromHeight,
      untilHeight: untilHeight,
    );
  }

  Future<List<DidOperation>> getDidOperations(
    DidData did,
    int fromHeight, {
    int untilHeight,
  }) async {
    return _didOperationsQuery(
      false,
      did,
      fromHeight,
      untilHeight: untilHeight,
    );
  }

  Future<List<DidOperation>> getDidOperationAttempts(
    DidData did,
    int fromHeight, {
    int untilHeight,
  }) async {
    return _didOperationsQuery(
      true,
      did,
      fromHeight,
      untilHeight: untilHeight,
    );
  }

  Future<List<DryRunOperationError>> checkTransactionValidity(
    List<OperationData> operationAttempts,
  ) async {
    final resp = await _layer2ApiPost(
      '/check-transaction-validity',
      json.encode(operationAttempts),
    );

    if (resp.statusCode == HttpStatus.ok) {
      return (json.decode(resp.body) as List<dynamic>)
          .map((e) => DryRunOperationError.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<List<DidOperation>> _didOperationsQuery(
    bool includeAttempts,
    DidData did,
    int fromHeight, {
    int untilHeight,
  }) async {
    final path = includeAttempts ? 'operation-attempts' : 'operations';
    final resp = await _layer2ApiGet(
      _widthHeight('/did/${did.value}/$path/$fromHeight', untilHeight),
    );

    if (resp.statusCode == HttpStatus.ok) {
      return (json.decode(resp.body) as List<dynamic>)
          .map((e) => DidOperation.fromJson(e))
          .toList();
    } else if (resp.statusCode == HttpStatus.notFound) {
      return null;
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<List<TransactionIdHeight>> _didTransactionIdsQuery(
    bool includeAttempts,
    DidData did,
    int fromHeight, {
    int untilHeight,
  }) async {
    final path = includeAttempts ? 'transaction-attempts' : 'transactions';
    final resp = await _layer2ApiGet(
      _widthHeight('/did/${did.value}/$path/$fromHeight', untilHeight),
    );

    if (resp.statusCode == HttpStatus.ok) {
      return (json.decode(resp.body) as List<dynamic>)
          .map((e) => TransactionIdHeight.fromJson(e))
          .toList();
    } else if (resp.statusCode == HttpStatus.notFound) {
      return null;
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  String _widthHeight(String path, int height) {
    return height == null ? path : '$path/$height';
  }

  Future<Response> _layer2ApiGet(String path) async {
    return _client.get(
      '${_networkConfig.host}:${_networkConfig.port}/morpheus/v1$path',
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  Future<Response> _layer2ApiPost(String path, dynamic body) async {
    return _client.post(
      '${_networkConfig.host}:${_networkConfig.port}/morpheus/v1$path',
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );
  }
}