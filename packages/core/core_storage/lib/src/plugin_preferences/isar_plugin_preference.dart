import 'package:core_contracts/core_contracts.dart';
import 'package:isar_community/isar.dart';

part 'isar_plugin_preference.g.dart';

@collection
class IsarPluginPreference {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String pluginId;

  late bool isEnabled;
  late int sortOrder;

  IsarPluginPreference();

  IsarPluginPreference.fromDomain(UserPluginPreference preference)
      : pluginId = preference.pluginId,
        isEnabled = preference.isEnabled,
        sortOrder = preference.sortOrder;

  UserPluginPreference toDomain() => UserPluginPreference(
        pluginId: pluginId,
        isEnabled: isEnabled,
        sortOrder: sortOrder,
      );
}
