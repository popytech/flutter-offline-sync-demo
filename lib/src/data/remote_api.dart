import 'dart:async';

import '../models/sync_models.dart';

abstract interface class RemoteApi {
  Future<void> apply(
    SyncOperation operation, {
    required AppRecord record,
  });
}

class MockRemoteApi implements RemoteApi {
  MockRemoteApi({this.failureEvery = 0, this.latency = const Duration(milliseconds: 450)});

  final int failureEvery;
  final Duration latency;
  int _calls = 0;
  final Set<String> _processedKeys = <String>{};

  @override
  Future<void> apply(
    SyncOperation operation, {
    required AppRecord record,
  }) async {
    if (_processedKeys.contains(operation.idempotencyKey)) return;

    await Future<void>.delayed(latency);
    _calls += 1;

    if (failureEvery > 0 && _calls % failureEvery == 0) {
      throw const RemoteSyncException('Simulated temporary network/server failure');
    }

    _processedKeys.add(operation.idempotencyKey);
  }
}

class RemoteSyncException implements Exception {
  const RemoteSyncException(this.message);
  final String message;

  @override
  String toString() => 'RemoteSyncException: $message';
}
