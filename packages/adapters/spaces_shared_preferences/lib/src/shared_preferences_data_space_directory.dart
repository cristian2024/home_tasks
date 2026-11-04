import 'dart:async';
import 'dart:convert';

import 'package:core_di/core_di.dart';
import 'package:core_spaces/core_spaces.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registra [SharedPreferencesDataSpaceDirectory] como `DataSpaceDirectory`.
/// Quien compone la app solo lo elige:
///
/// ```dart
/// adapters: <DependencyModule>[SharedPreferencesSpaces()]
/// ```
class SharedPreferencesSpaces implements DependencyModule {
  const SharedPreferencesSpaces();

  @override
  Future<void> register(ServiceLocator services) async =>
      services.registerSingleton<DataSpaceDirectory>(SharedPreferencesDataSpaceDirectory());
}

/// [DataSpaceDirectory] en `shared_preferences`. Guarda la lista y el activo
/// en una sola clave ([key]), así que cada cambio es atómico: nunca queda una
/// lista sin activo. Los cambios se aplican de uno en uno.
class SharedPreferencesDataSpaceDirectory implements DataSpaceDirectory {
  SharedPreferencesDataSpaceDirectory({this.key = defaultKey});

  static const String defaultKey = 'spaces.directory';

  /// Clave de `shared_preferences` donde se guarda todo.
  final String key;

  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  Future<void> _pending = Future<void>.value();

  @override
  Future<List<DataSpace>> spaces() async => sortSpaces((await _read()).spaces.values);

  @override
  Stream<List<DataSpace>> watchSpaces() {
    late final StreamController<List<DataSpace>> controller;
    StreamSubscription<void>? subscription;
    controller = StreamController<List<DataSpace>>(
      onListen: () {
        unawaited(spaces().then(controller.add));
        subscription = _changes.stream.listen((_) => unawaited(spaces().then(controller.add)));
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
  Future<DataSpace?> active() async {
    final _Snapshot snapshot = await _read();
    return snapshot.spaces[snapshot.activeId];
  }

  @override
  Future<void> setActive(String spaceId) => _update((_Snapshot snapshot) {
        if (!snapshot.spaces.containsKey(spaceId)) {
          throw UnknownDataSpaceException(spaceId);
        }
        return _Snapshot(activeId: spaceId, spaces: snapshot.spaces);
      }, notify: false);

  @override
  Future<void> save(DataSpace space) => _update((_Snapshot snapshot) {
        checkCanSaveSpace(space, snapshot.spaces.values);
        return _Snapshot(
          activeId: snapshot.activeId ?? space.id,
          spaces: <String, DataSpace>{...snapshot.spaces, space.id: space},
        );
      });

  @override
  Future<void> remove(String spaceId) => _update((_Snapshot snapshot) {
        if (spaceId == snapshot.activeId) {
          throw ActiveDataSpaceRemovalException(spaceId);
        }
        if (!snapshot.spaces.containsKey(spaceId)) {
          return null;
        }
        return _Snapshot(
          activeId: snapshot.activeId,
          spaces: Map<String, DataSpace>.of(snapshot.spaces)..remove(spaceId),
        );
      });

  /// Aplica [change] (que devuelve `null` si no hay nada que guardar) después
  /// de los cambios anteriores.
  Future<void> _update(_Snapshot? Function(_Snapshot snapshot) change, {bool notify = true}) {
    final Future<void> result = _pending.then((_) async {
      final _Snapshot? next = change(await _read());
      if (next == null) {
        return;
      }
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString(key, jsonEncode(next.toJson()));
      if (notify) {
        _changes.add(null);
      }
    });
    _pending = result.catchError((Object _) {});
    return result;
  }

  Future<_Snapshot> _read() async {
    final String? stored = (await SharedPreferences.getInstance()).getString(key);
    if (stored == null) {
      return const _Snapshot(activeId: null, spaces: <String, DataSpace>{});
    }
    try {
      return _Snapshot.fromJson(jsonDecode(stored) as Map<String, Object?>);
    } on Object catch (error) {
      // Sin la lista no se sabe qué base abrir: mejor fallar que empezar de
      // cero y dejar los datos de los espacios sin lista.
      throw StateError('La lista de espacios guardada no se puede leer: $error');
    }
  }
}

class _Snapshot {
  const _Snapshot({required this.activeId, required this.spaces});

  factory _Snapshot.fromJson(Map<String, Object?> json) => _Snapshot(
        activeId: json['active'] as String?,
        spaces: <String, DataSpace>{
          for (final DataSpace space in (json['spaces']! as List<Object?>)
              .map((Object? item) => _spaceFromJson(item! as Map<String, Object?>)))
            space.id: space,
        },
      );

  final String? activeId;
  final Map<String, DataSpace> spaces;

  Map<String, Object?> toJson() => <String, Object?>{
        'v': 1,
        'active': activeId,
        'spaces': <Map<String, Object?>>[
          for (final DataSpace space in spaces.values)
            <String, Object?>{
              'id': space.id,
              'name': space.name,
              'database': space.databaseName,
              'createdAt': space.createdAt.toIso8601String(),
              'household': space.householdId,
            },
        ],
      };
}

DataSpace _spaceFromJson(Map<String, Object?> json) => DataSpace(
      id: json['id']! as String,
      name: json['name']! as String,
      databaseName: json['database']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      householdId: json['household'] as String?,
    );
