import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:iop_sdk/crypto.dart';
import 'package:iop_sdk/layer2.dart';
import 'package:iop_sdk/src/coeus/bundle.dart';
import 'package:iop_sdk/src/coeus/operation.dart';
import 'package:iop_sdk/src/coeus/tx.dart';
import 'package:iop_sdk/layer1.dart';
import 'package:iop_sdk/src/layer1/hydra_tx.dart';
import 'package:iop_sdk/utils.dart';
import 'package:iop_sdk/network.dart';

class Layer1Api {
  final Client _client = Client();
  final NetworkConfig _networkConfig;

  Layer1Api._(this._networkConfig);

  static Layer1Api createApi(NetworkConfig networkConfig) =>
      Layer1Api._(networkConfig);

  Future<NodeCryptoConfigResponse> getNodeCryptoConfig() async {
    final resp = await _layer1ApiGet('/node/configuration/crypto');

    if (resp.statusCode == HttpStatus.ok) {
      final body = json.decode(resp.body);
      return NodeCryptoConfigResponse.fromJson(body['data']);
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<int> getCurrentHeight() async {
    final resp = await _layer1ApiGet('/blockchain');

    if (resp.statusCode == HttpStatus.ok) {
      final body = json.decode(resp.body);
      final blockchainResp = BlockchainResponse.fromJson(body['data']);
      return blockchainResp.block.height;
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<String> sendTransferTx(
    String senderAddress,
    String targetAddress,
    int amountInFlake,
    HydraPrivate hydraPrivate, {
    int? nonce,
  }) async {
    final senderBip44PubKey = hydraPrivate.public.keyByAddress(senderAddress);
    nonce ??= (await getWalletNonce(senderAddress)) + 1;

    final builder = HydraTxBuilder(_networkConfig.network);
    final transferTx = builder.transfer(
      senderBip44PubKey.publicKey(),
      targetAddress,
      amountInFlake,
      nonce,
    );

    final signedTx = hydraPrivate.signHydraTransaction(
      senderAddress,
      transferTx,
    );

    final resp = await sendTx(signedTx.toString());
    return resp;
  }

  @Deprecated('Not red carpet methods are not used anymore. Use sendTransferTx')
  Future<String> sendTransferTxWithPassphrase(
    String passphrase,
    String targetAddress,
    int amountInFlake, {
    int? nonce,
  }) async {
    final secpPrivKey = SecpPrivateKey.fromArkPassphrase(passphrase);
    final senderPubKey = secpPrivKey.publicKey();
    nonce ??= (await getWalletNonce(senderPubKey.toString())) + 1;

    final builder = HydraTxBuilder(_networkConfig.network);
    final transferTx = builder.transfer(
      senderPubKey,
      targetAddress,
      amountInFlake,
      nonce,
    );

    final signedTx = secpPrivKey.signHydraTransaction(transferTx);

    final resp = await sendTx(signedTx.toString());
    return resp;
  }

  Future<String> sendVoteOrUnvote(
    String voterAddress,
    HydraPrivate hydraPrivate,
    String Function(
      HydraTxBuilder builder,
      SecpPublicKey senderPubKey,
      int nonce,
    )
        createTx,
    int? nonce,
  ) async {
    final voterBip44PubKey = hydraPrivate.public.keyByAddress(voterAddress);
    nonce ??= (await getWalletNonce(voterAddress)) + 1;

    final builder = HydraTxBuilder(_networkConfig.network);
    final transferTx = createTx(builder, voterBip44PubKey.publicKey(), nonce);

    final signedTx = hydraPrivate.signHydraTransaction(
      voterAddress,
      transferTx,
    );

    final resp = await sendTx(signedTx.toString());
    return resp;
  }

  Future<String> sendVoteTx(
    String voterAddress,
    SecpPublicKey delegate,
    HydraPrivate hydraPrivate, {
    int? nonce,
  }) async {
    return await sendVoteOrUnvote(
      voterAddress,
      hydraPrivate,
      (builder, senderPubKey, nonce) =>
          builder.vote(senderPubKey, delegate, nonce),
      nonce,
    );
  }

  Future<String> sendUnvoteTx(
    String voterAddress,
    SecpPublicKey delegate,
    HydraPrivate hydraPrivate, {
    int? nonce,
  }) async {
    return await sendVoteOrUnvote(
      voterAddress,
      hydraPrivate,
      (builder, senderPubKey, nonce) =>
          builder.unvote(senderPubKey, delegate, nonce),
      nonce,
    );
  }

  Future<String> sendMorpheusTx(
    String senderAddress,
    MorpheusAsset morpheusAsset,
    HydraPrivate hydraPrivate, {
    int? nonce,
  }) async {
    final senderBip44PubKey = hydraPrivate.public.keyByAddress(senderAddress);
    nonce ??= (await getWalletNonce(senderAddress)) + 1;

    final morpheusTx = MorpheusTxBuilder.build(
      _networkConfig.network,
      morpheusAsset,
      senderBip44PubKey.publicKey(),
      nonce,
    );

    final signedTx =
        hydraPrivate.signHydraTransaction(senderAddress, morpheusTx);

    return await sendTx(signedTx.toString());
  }

  @Deprecated('Not red carpet methods are not used anymore. Use sendMorpheusTx')
  Future<String> sendMorpheusTxWithPassphrase(
    MorpheusAsset morpheusAsset,
    String passphrase, {
    int? nonce,
  }) async {
    final secpPrivKey = SecpPrivateKey.fromArkPassphrase(passphrase);
    final senderPubKey = secpPrivKey.publicKey();
    nonce ??= (await getWalletNonce(senderPubKey.toString())) + 1;

    final morpheusTx = MorpheusTxBuilder.build(
      _networkConfig.network,
      morpheusAsset,
      senderPubKey,
      nonce,
    );

    final signedTx = secpPrivKey.signHydraTransaction(morpheusTx);
    return await sendTx(signedTx.toString());
  }

  Future<String> sendCoeusTx(
    String fromAddress,
    List<UserOperation> userOperations,
    HydraPrivate hydraPrivate, {
    int? layer1SenderNonce,
    int? layer2PublicKeyNonce,
  }) async {
    // TODO: we have to get the nonce from somewhere else rather using layer2api
    final layer2Api = Layer2Api.createCoeusApi(_networkConfig);
    final secpPubKey =
        hydraPrivate.public.keyByAddress(fromAddress).publicKey();
    final secpPrivKey = hydraPrivate.keyByPublicKey(secpPubKey).privateKey();
    final noncedBuilder = NoncedBundleBuilder.create();
    userOperations.forEach((element) => noncedBuilder.add(element));

    layer2PublicKeyNonce ??=
        (await layer2Api.getLastNonce(PublicKey.fromSecp(secpPubKey))) + 1;
    final noncedBundle = noncedBuilder.build(layer2PublicKeyNonce);
    final signedBundle = noncedBundle.sign(PrivateKey.fromSecp(secpPrivKey));

    layer1SenderNonce ??= (await getWalletNonce(fromAddress)) + 1;
    final tx = CoeusTxBuilder.create(_networkConfig.network).build(
      signedBundle,
      secpPubKey,
      layer1SenderNonce,
    );

    final signedTx = secpPrivKey.signHydraTransaction(tx);
    return await sendTx(signedTx.toString());
  }

  Future<TransactionStatusResponse?> getTxnStatus(String txId) async {
    final resp = await _layer1ApiGet('/transactions/$txId');

    if (resp.statusCode == HttpStatus.ok) {
      final body = json.decode(resp.body);
      return TransactionStatusResponse.fromJson(body['data']);
    } else if (resp.statusCode == HttpStatus.notFound) {
      return null;
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<WalletResponse?> getWallet(String addressOrPublicKey) async {
    final resp = await _layer1ApiGet('/wallets/$addressOrPublicKey');

    if (resp.statusCode == HttpStatus.ok) {
      final body = json.decode(resp.body);
      return WalletResponse.fromJson(body['data']);
    } else if (resp.statusCode == HttpStatus.notFound) {
      return null;
    }

    return Future.error(HttpResponseError(resp.statusCode, resp.body));
  }

  Future<int> getWalletNonce(String addressOrPublicKey) async {
    final wallet = await getWallet(addressOrPublicKey);
    return wallet != null ? int.parse(wallet.nonce) : 0;
  }

  Future<int> getWalletBalance(String addressOrPublicKey) async {
    final wallet = await getWallet(addressOrPublicKey);
    return wallet != null ? int.parse(wallet.balance) : 0;
  }

  Future<String> sendTx(String signedTx) async {
    final resp = await _layer1ApiPost('/transactions', signedTx);

    if (resp.statusCode != HttpStatus.ok) {
      return Future.error(HttpResponseError(resp.statusCode, resp.body));
    }

    final body = json.decode(resp.body);
    final txResp = SendTransactionResponse.fromJson(body);

    if (txResp.data.invalid.isNotEmpty) {
      return Future.error(HttpResponseError(
        resp.statusCode,
        'Transaction failed: ${json.encode(txResp.errors)}',
      ));
    }

    if (txResp.data.accept.length > 1) {
      return Future.error(HttpResponseError(
        resp.statusCode,
        'sendTx expected 1 accepted tx, got ${txResp.data.accept.length}. Response: ${resp.body}',
      ));
    }
    return txResp.data.accept[0];
  }

  Future<Response> _layer1ApiPost(String path, dynamic body) async {
    return _client.post(
      Uri.parse('${_networkConfig.host}:${_networkConfig.port}/api/v2$path'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );
  }

  Future<Response> _layer1ApiGet(String path) async {
    final url = '${_networkConfig.host}:${_networkConfig.port}/api/v2$path';
    return _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
}
