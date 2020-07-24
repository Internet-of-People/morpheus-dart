import 'package:iop_sdk/crypto.dart';
import 'package:iop_sdk/layer1.dart';
import 'package:iop_sdk/ssi.dart';

class OperationAttemptsBuilder {
  final List<OperationData> _attempts = [];

  OperationAttemptsBuilder();

  OperationAttemptsBuilder registerBeforeProof(ContentId contentId) {
    final data = RegisterBeforeProofData(contentId);
    _attempts.add(data);
    return this;
  }

  // TODO enable adding DID-related signed transactions as well

  List<OperationData> getAttempts() {
    return _attempts;
  }
}

class SignedOperationAttemptsBuilder {
  static SignedOperationsData tempSign(
    MorpheusPrivate priv,
    KeyId id,
    List<SignableOperationData> signables,
  ) {
    final opBytes = SignedOperationsData.serialize(signables);
    final signedBytes = priv.signDidOperations(id, opBytes);
    final signedOp = SignedOperationsData(
      signables,
      signedBytes.signature.publicKey,
      signedBytes.signature.bytes,
    );
    return signedOp;
  }
}