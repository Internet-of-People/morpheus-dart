import 'dart:io';
import 'dart:convert';
import 'package:meta/meta.dart';

import 'crypto.dart';
import 'sdk.dart';


// TODO should these be moved to types instead?
enum Network {
    LocalTestNet,
    TestNet,
    DevNet,
    MainNet,
}

extension NetworkProperties on Network {
    String get seedServerUrl => const {
        Network.LocalTestNet: 'http://127.0.0.1',
        Network.TestNet: 'http://35.187.56.222',
        Network.DevNet: 'http://35.240.62.119',
        Network.MainNet: 'http://35.195.150.223',
    }[this];
}

// TODO what goes here?
class HydraAddress {
    String address;
    HydraAddress(this.address) {
        // TODO validate address
    }
}

class TransactionId {
    String txId;
    TransactionId(this.txId);
    @override String toString() { return txId; }
}

// TODO work this out
abstract class Transaction {}

class HydraTransferTransaction extends Transaction {
    HydraAddress toAddress;
    BigInt flakes;
    BigInt fee;

    HydraTransferTransaction({
        @required this.toAddress,
        @required this.flakes,
        this.fee
        // TODO hexencoded binary
        // String vendorField,
    }) {
        // TODO validate recipient address format
    }
    @override String toString() { throw UnimplementedError(); }
}

// TODO this will belong to a Hydra subtree interface of Vault after subtrees are implemented
extension HydraTransactionSignatures on Vault {
    Future<SignedHydraTransaction> signHydraTransfer(HydraTransferTransaction tx, HydraAddress senderAddress)
        { throw UnimplementedError(); }
    Future<SignedHydraTransaction> signMorpheusTransaction(MorpheusTransaction tx, HydraAddress gasAddress)
        { throw UnimplementedError(); }
}


// TODO work this out
class MorpheusOperationAttempt {}
class MorpheusSignableOperationAttempt extends MorpheusOperationAttempt {}
class MorpheusOperationBuilder {}
class MorpheusTransaction extends Transaction {
    @override String toString() { throw UnimplementedError(); }
}
class MorpheusTransactionBuilder {}

// TODO this will belong to a Hydra subtree interface of Vault after subtrees are implemented
extension MorpheusTransactionSignatures on Vault {
    Future<MorpheusSigned<MorpheusSignableOperationAttempt>> signDidOperation
        (MorpheusSignableOperationAttempt tx, Authentication authentication)
    { throw UnimplementedError(); }
}


class Layer1 {
    Network network;

    Layer1(this.network);

    Future<BigInt> getWalletNonce() {
        // TODO
        return Future.value(BigInt.from(1));
    }

    Future<bool> getTransactionStatus(TransactionId txId) async {
        return Future.value(true);
    }

    Future<TransactionId> sendTransaction(SignedHydraTransaction hydraTx) async {
        var url = Uri.parse(network.seedServerUrl + ':4703/api/v2/transactions');
        var client = HttpClient();
        var req = await client.postUrl(url)
            ..headers.contentType = ContentType.json
            ..write(hydraTx.toString());
        var resp = await req.close();
        resp.transform(utf8.decoder).listen((content) {
            print('Transaction response: ${content}');
        });
        // TODO process received response content to create a transactioId
        return Future.value(TransactionId('transactionId'));
    }

    // TODO implement sendTransferTx() and sendMorpheusTx() here
    // TODO getWallet(nonce/balance/etc), sendTx(RawTxJson), getCurrentHeight()
}