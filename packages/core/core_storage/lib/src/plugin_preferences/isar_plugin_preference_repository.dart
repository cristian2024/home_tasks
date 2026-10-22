import 'package:core_contracts/core_contracts.dart';
import 'package:isar_community/isar.dart';

import 'isar_plugin_preference.dart';

class IsarPluginPreferenceRepository implements PluginPreferenceRepository {
  IsarPluginPreferenceRepository(this._isar);

  final Isar _isar;

  IsarCollection<IsarPluginPreference> get _collection => _isar.isarPluginPreferences;

  @override
  Future<List<UserPluginPreference>> getAll() async {
    final rows = await _collection.where().findAll();
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<void> save(UserPluginPreference preference) => saveAll([preference]);

  @override
  Future<void> saveAll(List<UserPluginPreference> preferences) async {
    await _isar.writeTxn(() async {
      await _collection.putAllByPluginId([
        for (final preference in preferences) IsarPluginPreference.fromDomain(preference),
      ]);
    });
  }

  @override
  Stream<List<UserPluginPreference>> watch() => _collection
      .where()
      .watch(fireImmediately: true)
      .map((rows) => [for (final row in rows) row.toDomain()]);
}
