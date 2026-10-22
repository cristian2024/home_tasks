import 'package:core_contracts/core_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const preference = UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 0);

  test('copyWith conserva pluginId y reemplaza solo los campos dados', () {
    expect(
      preference.copyWith(isEnabled: false),
      const UserPluginPreference(pluginId: 'a', isEnabled: false, sortOrder: 0),
    );
    expect(
      preference.copyWith(sortOrder: 3),
      const UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 3),
    );
    expect(preference.copyWith(), preference);
  });

  test('igualdad por valor', () {
    const same = UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 0);
    const other = UserPluginPreference(pluginId: 'b', isEnabled: true, sortOrder: 0);

    expect(preference, same);
    expect(preference.hashCode, same.hashCode);
    expect(preference, isNot(other));
  });
}
