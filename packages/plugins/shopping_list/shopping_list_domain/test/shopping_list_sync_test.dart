import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:shopping_list_domain/testing.dart';

ShoppingListSyncSubject _subject() {
  final InMemoryChangeLog log = InMemoryChangeLog();
  final InMemoryShoppingListRepository repository = InMemoryShoppingListRepository(
    hlcClock: HlcClock(deviceId: 'device-local', clock: FixedClock(DateTime.utc(2026, 10, 31))),
    changeLog: log,
  );
  return ShoppingListSyncSubject(
    repository: repository,
    participant: ShoppingListSyncParticipant(store: repository, repository: repository),
    log: log,
  );
}

void main() {
  shoppingListSyncContract('InMemoryShoppingListRepository', create: _subject);
  shoppingListRepositoryContract('en memoria, sincronizado', create: () => _subject().repository);
}
