import 'package:core_contracts/core_contracts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Plugin implements HomePlugin {
  @override
  String get id => 'plain';

  @override
  String get nameKey => 'plain.name';

  @override
  String get descriptionKey => 'plain.description';

  @override
  IconData get icon => const IconData(0);

  @override
  String get version => '1.0.0';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  List<RouteBase> get routes => <RouteBase>[];

  @override
  Widget buildDashboardTile(BuildContext context) => const SizedBox.shrink();
}

class _PluginWithEntry extends _Plugin implements HomePluginEntryRoute {
  @override
  String get entryRoute => '/plain';
}

void main() {
  test('la ruta de entrada es opcional: la app la busca con un patrón de tipo', () {
    final List<HomePlugin> plugins = <HomePlugin>[_Plugin(), _PluginWithEntry()];

    expect(<String?>[
      for (final HomePlugin plugin in plugins)
        switch (plugin) {
          HomePluginEntryRoute(:final String entryRoute) => entryRoute,
          _ => null,
        },
    ], <String?>[null, '/plain']);
  });
}
