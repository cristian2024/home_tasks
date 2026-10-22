import 'dart:async';

import 'package:core_contracts/core_contracts.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class FakePlugin implements HomePlugin {
  FakePlugin(
    this.id, {
    this.available = true,
    this.initializeError,
    this.disposeError,
  });

  @override
  final String id;

  bool available;
  Object? initializeError;
  Object? disposeError;

  int initializeCalls = 0;
  int disposeCalls = 0;

  @override
  String get nameKey => '$id.name';

  @override
  String get descriptionKey => '$id.description';

  @override
  IconData get icon => const IconData(0xe000);

  @override
  String get version => '1.0.0';

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (initializeError != null) {
      throw initializeError!;
    }
  }

  @override
  List<RouteBase> get routes => const [];

  @override
  Widget buildDashboardTile(BuildContext context) => const SizedBox.shrink();

  @override
  Future<void> dispose() async {
    disposeCalls++;
    if (disposeError != null) {
      throw disposeError!;
    }
  }
}

class InMemoryPluginPreferenceRepository implements PluginPreferenceRepository {
  final Map<String, UserPluginPreference> _store = {};
  final StreamController<List<UserPluginPreference>> _changes =
      StreamController.broadcast();

  @override
  Future<List<UserPluginPreference>> getAll() async => _store.values.toList();

  @override
  Future<void> save(UserPluginPreference preference) => saveAll([preference]);

  @override
  Future<void> saveAll(List<UserPluginPreference> preferences) async {
    for (final preference in preferences) {
      _store[preference.pluginId] = preference;
    }
    _changes.add(_store.values.toList());
  }

  @override
  Stream<List<UserPluginPreference>> watch() => _changes.stream;

  Future<void> close() => _changes.close();
}
