import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';
import 'package:task_list_domain/task_list_domain.dart';
import 'package:task_list_domain/testing.dart';

TaskListSyncSubject _subject() {
  final InMemoryChangeLog log = InMemoryChangeLog();
  final InMemoryTaskListRepository repository = InMemoryTaskListRepository(
    hlcClock: HlcClock(deviceId: 'device-local', clock: FixedClock(DateTime.utc(2026, 11, 7))),
    changeLog: log,
  );
  return TaskListSyncSubject(
    repository: repository,
    participant: TaskListSyncParticipant(store: repository),
    log: log,
  );
}

void main() {
  taskListSyncContract('InMemoryTaskListRepository', create: _subject);
  taskListRepositoryContract('en memoria, sincronizado', create: () => _subject().repository);
}
