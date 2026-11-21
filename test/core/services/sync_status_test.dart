import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/core/services/sync_status.dart';

void main() {
  test('truth table', () {
    expect(
      resolveSyncStatus(online: false, hasPendingWrites: false),
      SyncStatus.offline,
    );
    expect(
      resolveSyncStatus(online: false, hasPendingWrites: true),
      SyncStatus.offline,
    );
    expect(
      resolveSyncStatus(online: true, hasPendingWrites: true),
      SyncStatus.syncing,
    );
    expect(
      resolveSyncStatus(online: true, hasPendingWrites: false),
      SyncStatus.synced,
    );
  });
}
