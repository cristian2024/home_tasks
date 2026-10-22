class UserPluginPreference {
  final String pluginId;
  final bool isEnabled;
  final int sortOrder;

  const UserPluginPreference({
    required this.pluginId,
    required this.isEnabled,
    required this.sortOrder,
  });

  UserPluginPreference copyWith({
    bool? isEnabled,
    int? sortOrder,
  }) {
    return UserPluginPreference(
      pluginId: pluginId,
      isEnabled: isEnabled ?? this.isEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserPluginPreference &&
      other.pluginId == pluginId &&
      other.isEnabled == isEnabled &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(pluginId, isEnabled, sortOrder);

  @override
  String toString() =>
      'UserPluginPreference(pluginId: $pluginId, isEnabled: $isEnabled, sortOrder: $sortOrder)';
}
