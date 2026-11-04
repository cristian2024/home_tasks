import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:item_tracker_domain/testing.dart';

ItemTrackerSyncSubject _subject() {
  final InMemoryChangeLog log = InMemoryChangeLog();
  final InMemoryHouseholdItemRepository repository = InMemoryHouseholdItemRepository(
    hlcClock: HlcClock(deviceId: 'device-local', clock: FixedClock(DateTime.utc(2026, 10, 31))),
    changeLog: log,
  );
  return ItemTrackerSyncSubject(
    repository: repository,
    participant: ItemTrackerSyncParticipant(store: repository, repository: repository),
    log: log,
  );
}

void main() {
  itemTrackerSyncContract('InMemoryHouseholdItemRepository', create: _subject);
  householdItemRepositoryContract('en memoria, sincronizado', create: () => _subject().repository);
}
