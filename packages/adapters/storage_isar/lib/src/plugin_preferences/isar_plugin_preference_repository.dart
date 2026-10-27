import 'package:core_contracts/core_contracts.dart';
import 'package:isar_community/isar.dart';

import 'isar_plugin_preference.dart';

/// [PluginPreferenceRepository] sobre Isar. Cumple
/// `pluginPreferenceRepositoryContract`.
class IsarPluginPreferenceRepository implements PluginPreferenceRepository {
  IsarPluginPreferenceRepository(this._isar);

  final Isar _isar;

  IsarCollection<IsarPluginPreference> get _collection => _isar.isarPluginPreferences;

  @override
  Future<List<UserPluginPreference>> getAll() async => <UserPluginPreference>[
        for (final IsarPluginPreference row in await _collection.where().findAll()) row.toDomain(),
      ];

  @override
  Future<void> save(UserPluginPreference preference) => saveAll(<UserPluginPreference>[preference]);

  @override
  Future<void> saveAll(List<UserPluginPreference> preferences) => _isar.writeTxn(
        () => _collection.putAllByPluginId(<IsarPluginPreference>[
          for (final UserPluginPreference preference in preferences) IsarPluginPreference.fromDomain(preference),
        ]),
      );

  @override
  Stream<List<UserPluginPreference>> watch() => _collection.where().watch(fireImmediately: true).map(
        (List<IsarPluginPreference> rows) => <UserPluginPreference>[
          for (final IsarPluginPreference row in rows) row.toDomain(),
        ],
      );
}
