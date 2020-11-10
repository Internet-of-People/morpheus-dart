import 'dart:ffi';

import 'package:iop_sdk/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:iop_sdk/src/ffi/dart_api.dart';
import 'package:iop_sdk/src/ffi/ffi.dart';


class SubtreePolicies implements Disposable {
  Pointer<Void> _ffi;
  bool _owned;

  SubtreePolicies(this._ffi, this._owned);

  factory SubtreePolicies.create() =>
      SubtreePolicies(DartApi.native.coeusSubtreePolicies.create(), true);

  SubtreePolicies withSchema(String schema) {
    final nativeSchema = Utf8.toUtf8(schema);
    try {
      final policies = DartApi.native.coeusSubtreePolicies
          .withSchema(_ffi, nativeSchema)
          .extract((res) => res.asPointer<Void>());
      return SubtreePolicies(policies, true);
    } finally {
      free(nativeSchema);
      // dispose(); // TODO Should be done automatically by Dart
    }
  }

  SubtreePolicies withExpiration(int maxExpiryBlocks) {
    try {
      final policies = DartApi.native.coeusSubtreePolicies
          .withExpiration(_ffi, maxExpiryBlocks)
          .extract((res) => res.asPointer<Void>());
      return SubtreePolicies(policies, true);
    } finally {
      // dispose(); // TODO Should be done automatically by Dart
    }
  }

  @override
  void dispose() {
    if (_owned) {
      DartApi.native.coeusSubtreePolicies.delete(_ffi);
      _ffi = nullptr;
      _owned = false;
    }
  }
}


class UserOperation implements Disposable {
  Pointer<Void> _ffi;
  bool _owned;

  // NOTE needed for NonceBundleBuilder
  Pointer<Void> get ffi => _ffi;

  UserOperation(this._ffi, this._owned);

  UserOperation register(String domainName, String owner, SubtreePolicies subtreePolicies,
        String data, int expiresAtHeight)
  {
    final nativeDomainName = Utf8.toUtf8(domainName);
    final nativeOwner = Utf8.toUtf8(owner);
    final nativeData = Utf8.toUtf8(data);
    try {
      final op = DartApi.native.coeusUserOperation
          .opRegister(nativeDomainName, nativeOwner, subtreePolicies._ffi, nativeData, expiresAtHeight)
          .extract((res) => res.asPointer<Void>());
      return UserOperation(op, true);
    } finally {
      free(nativeData);
      free(nativeOwner);
      free(nativeDomainName);
    }
  }

  factory UserOperation.update(String domainName, String schema) {
    final nativeDomainName = Utf8.toUtf8(domainName);
    final nativeSchema = Utf8.toUtf8(schema);
    try {
      final op = DartApi.native.coeusUserOperation
          .opUpdate(nativeDomainName, nativeSchema)
          .extract((res) => res.asPointer<Void>());
      return UserOperation(op, true);
    } finally {
      free(nativeSchema);
      free(nativeDomainName);
    }
  }

  UserOperation renew(String domainName, int expiresAtHeight) {
    final nativeDomainName = Utf8.toUtf8(domainName);
    try {
      final op = DartApi.native.coeusUserOperation
          .opRenew(nativeDomainName, expiresAtHeight)
          .extract((res) => res.asPointer<Void>());
      return UserOperation(op, true);
    } finally {
      free(nativeDomainName);
    }
  }

  UserOperation transfer(String domainName, String toOwner) {
    final nativeDomainName = Utf8.toUtf8(domainName);
    final nativeToOwner = Utf8.toUtf8(toOwner);
    try {
      final op = DartApi.native.coeusUserOperation
          .opTransfer(nativeDomainName, nativeToOwner)
          .extract((res) => res.asPointer<Void>());
      return UserOperation(op, true);
    } finally {
      free(nativeToOwner);
      free(nativeDomainName);
    }
  }

  UserOperation delete(String domainName) {
    final nativeDomainName = Utf8.toUtf8(domainName);
    try {
      final op = DartApi.native.coeusUserOperation
          .opDelete(nativeDomainName)
          .extract((res) => res.asPointer<Void>());
      return UserOperation(op, true);
    } finally {
      free(nativeDomainName);
    }
  }

  @override
  void dispose() {
    if (_owned) {
      DartApi.native.coeusUserOperation.delete(_ffi);
      _ffi = nullptr;
      _owned = false;
    }
  }
}