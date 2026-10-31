/// Dobles en memoria y tests de contrato de `core_spaces`.
library;

import 'dart:async';

import 'core_spaces.dart';

export 'src/testing/data_space_directory_contract.dart';
export 'src/testing/data_space_storage_contract.dart';

/// [DataSpaceDirectory] en memoria. Cumple `dataSpaceDirectoryContract`.
class InMemoryDataSpaceDirectory implements DataSpaceDirectory {
  final Map<String, DataSpace> _spaces = <String, DataSpace>{};
  String? _activeId;
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);

  @override
  Future<List<DataSpace>> spaces() async => sortSpaces(_spaces.values);

  @override
  Stream<List<DataSpace>> watchSpaces() {
    late final StreamController<List<DataSpace>> controller;
    StreamSubscription<void>? subscription;
    controller = StreamController<List<DataSpace>>(
      onListen: () {
        controller.add(sortSpaces(_spaces.values));
        subscription = _changes.stream.listen((_) => controller.add(sortSpaces(_spaces.values)));
      },
      // Sin devolver el futuro de cancel(): `first` lo esperaría y, con el
      // reloj simulado de testWidgets, no se completa.
      onCancel: () {
        unawaited(subscription?.cancel());
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  @override
  Future<DataSpace?> active() async => _spaces[_activeId];

  @override
  Future<void> setActive(String spaceId) async {
    if (!_spaces.containsKey(spaceId)) {
      throw UnknownDataSpaceException(spaceId);
    }
    _activeId = spaceId;
  }

  @override
  Future<void> save(DataSpace space) async {
    checkCanSaveSpace(space, _spaces.values);
    _spaces[space.id] = space;
    _activeId ??= space.id;
    _changes.add(null);
  }

  @override
  Future<void> remove(String spaceId) async {
    if (spaceId == _activeId) {
      throw ActiveDataSpaceRemovalException(spaceId);
    }
    if (_spaces.remove(spaceId) != null) {
      _changes.add(null);
    }
  }
}

/// [DataSpaceStorage] en memoria: las bases son nombres, abiertas o no.
/// Cumple `dataSpaceStorageContract`.
class InMemoryDataSpaceStorage implements DataSpaceStorage {
  InMemoryDataSpaceStorage({Iterable<String> databases = const <String>[]}) : _databases = databases.toSet();

  final Set<String> _databases;
  final Set<String> _open = <String>{};

  /// Crea la base [databaseName] (cerrada).
  void createDatabase(String databaseName) => _databases.add(databaseName);

  /// Abre la base [databaseName]: [delete] fallará hasta [closeDatabase].
  void openDatabase(String databaseName) => _open.add(databaseName);

  void closeDatabase(String databaseName) => _open.remove(databaseName);

  @override
  Future<Set<String>> databaseNames() async => Set<String>.of(_databases);

  @override
  Future<void> delete(String databaseName) async {
    if (_open.contains(databaseName)) {
      throw DataSpaceInUseException(databaseName);
    }
    _databases.remove(databaseName);
  }
}
