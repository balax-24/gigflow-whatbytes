enum SyncStatus { synced, syncing, offline }

SyncStatus resolveSyncStatus({
  required bool online,
  required bool hasPendingWrites,
}) {
  if (!online) return SyncStatus.offline;
  if (hasPendingWrites) return SyncStatus.syncing;
  return SyncStatus.synced;
}
