import 'package:core_contracts/core_contracts.dart';
import 'package:isar_community/isar.dart';

part 'isar_plugin_preference.g.dart';

/// Fila de preferencias de un plugin. El nombre de la clase es el de la
/// colección: no cambiarlo, o los datos guardados dejan de leerse.
@collection
class IsarPluginPreference {
  IsarPluginPreference();

  IsarPluginPreference.fromDomain(UserPluginPreference preference)
      : pluginId = preference.pluginId,
        isEnabled = preference.isEnabled,
        sortOrder = preference.sortOrder;

  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String pluginId;

  late bool isEnabled;
  late int sortOrder;

  UserPluginPreference toDomain() => UserPluginPreference(
        pluginId: pluginId,
        isEnabled: isEnabled,
        sortOrder: sortOrder,
      );
}
