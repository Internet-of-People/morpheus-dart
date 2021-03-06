import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:iop_sdk/crypto.dart';
import 'package:iop_sdk/src/ffi/dart_api.dart';
import 'package:iop_sdk/src/ffi/ffi.dart';
import 'package:iop_sdk/layer1.dart';
import 'package:iop_sdk/network.dart';

class HydraPlugin implements Disposable {
  static void init(
      Vault vault, String unlockPassword, Network network, int account) {
    final nativePwd = unlockPassword.toNativeUtf8();
    final nativeNet = network.networkNativeName.toNativeUtf8();
    try {
      return DartApi.native.hydraPlugin
          .init(vault.ffi, nativePwd, nativeNet, account)
          .extract((res) => res.asVoid);
    } finally {
      calloc.free(nativeNet);
      calloc.free(nativePwd);
    }
  }

  static HydraPlugin get(Vault vault, Network network, int account) {
    final nativeNet = network.networkNativeName.toNativeUtf8();
    try {
      final ffiPlugin = DartApi.native.hydraPlugin
          .get(vault.ffi, nativeNet, account)
          .extract((res) => res.asPointer<Void>());
      return HydraPlugin(ffiPlugin, true);
    } finally {
      calloc.free(nativeNet);
    }
  }

  Pointer<Void> _ffi;
  bool _owned;

  HydraPlugin(this._ffi, this._owned);

  HydraPrivate private(String unlockPassword) {
    final nativePwd = unlockPassword.toNativeUtf8();
    try {
      final ffiPrivate = DartApi.native.hydraPlugin
          .private(_ffi, nativePwd)
          .extract((res) => res.asPointer<Void>());
      return HydraPrivate(ffiPrivate, _owned);
    } finally {
      calloc.free(nativePwd);
    }
  }

  HydraPublic get public {
    final ffiPublic = DartApi.native.hydraPlugin
        .publicGet(_ffi)
        .extract((res) => res.asPointer<Void>());
    return HydraPublic(ffiPublic, true);
  }

  @override
  void dispose() {
    if (_owned) {
      DartApi.native.hydraPlugin.delete(_ffi);
      _ffi = nullptr;
      _owned = false;
    }
  }
}

class HydraPrivate implements Disposable {
  Pointer<Void> _ffi;
  bool _owned;

  HydraPrivate(this._ffi, this._owned);

  HydraPublic get public {
    final public = DartApi.native.hydraPrivate
        .publicGet(_ffi)
        .extract((res) => res.asPointer<Void>());
    return HydraPublic(public, true);
  }

  String get xpub {
    return DartApi.native.hydraPrivate.xpubGet(_ffi).intoString();
  }

  int get changeKeys {
    return DartApi.native.hydraPrivate.changeKeysGet(_ffi);
  }

  int get receiveKeys {
    return DartApi.native.hydraPrivate.receiveKeysGet(_ffi);
  }

  // TODO should be strongly typed, e.g. receiving HydraTransferTransaction,
  //      returning SignedContent and maybe extracting signer address from tx or using HydraAddress
  SignedHydraTransaction signHydraTransaction(String address, String tx) {
    // TODO should we dedicate a toJson() function for tx serialization?
    final nativeAddr = address.toNativeUtf8();
    final nativeTx = tx.toNativeUtf8();
    try {
      final signedTx = DartApi.native.hydraPrivate
          .signHydraTx(_ffi, nativeAddr, nativeTx)
          .extract((res) => res.asString);
      return SignedHydraTransaction(signedTx);
    } finally {
      calloc.free(nativeTx);
      calloc.free(nativeAddr);
    }
  }

  Bip44Key key(int idx) {
    final ffiKey = DartApi.native.hydraPrivate
        .key(_ffi, idx)
        .extract((resp) => resp.asPointer<Void>());
    return Bip44Key(ffiKey, true);
  }

  Bip44Key keyByPublicKey(SecpPublicKey secpPk) {
    final ffiKey = DartApi.native.hydraPrivate
        .keyByPk(_ffi, secpPk.ffi)
        .extract((resp) => resp.asPointer<Void>());
    return Bip44Key(ffiKey, true);
  }

  @override
  void dispose() {
    if (_owned) {
      DartApi.native.hydraPrivate.delete(_ffi);
      _ffi = nullptr;
      _owned = false;
    }
  }
}

class HydraPublic implements Disposable {
  Pointer<Void> _ffi;
  bool _owned;

  HydraPublic(this._ffi, this._owned);

  String get xpub {
    return DartApi.native.hydraPublic.xpubGet(_ffi).intoString();
  }

  int get changeKeys {
    return DartApi.native.hydraPublic.changeKeysGet(_ffi);
  }

  int get receiveKeys {
    return DartApi.native.hydraPublic.receiveKeysGet(_ffi);
  }

  Bip44PublicKey key(int idx) {
    final bip44PubKey = DartApi.native.hydraPublic
        .key(_ffi, idx)
        .extract((res) => res.asPointer<Void>());
    return Bip44PublicKey(bip44PubKey, true);
  }

  Bip44PublicKey keyByAddress(String address) {
    final nativeAddr = address.toNativeUtf8();
    try {
      final bip44PubKey = DartApi.native.hydraPublic
          .keyByAddress(_ffi, nativeAddr)
          .extract((res) => res.asPointer<Void>());
      return Bip44PublicKey(bip44PubKey, true);
    } finally {
      calloc.free(nativeAddr);
    }
  }

  @override
  void dispose() {
    if (_owned) {
      DartApi.native.hydraPublic.delete(_ffi);
      _ffi = nullptr;
      _owned = false;
    }
  }
}
