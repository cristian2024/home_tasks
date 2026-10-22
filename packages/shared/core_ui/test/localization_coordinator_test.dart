import 'package:core_ui/core_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalizationCoordinator coordinator;

  setUp(() => coordinator = LocalizationCoordinator());
  tearDown(() => coordinator.setLanguage('es'));

  test('el idioma por defecto es español', () {
    expect(coordinator.languageCode.value, 'es');
    expect(commonStrings.common.cancel, 'Cancelar');
  });

  test('setLanguage aplica el idioma a core_ui y a los paquetes registrados', () {
    final applied = <String>[];
    coordinator
      ..register('plugin_a', applied.add)
      ..setLanguage('en');

    expect(applied, ['es', 'en']);
    expect(coordinator.languageCode.value, 'en');
    expect(commonStrings.common.cancel, 'Cancel');
  });

  test('un idioma no soportado cae en español', () {
    final applied = <String>[];
    coordinator
      ..register('plugin_a', applied.add)
      ..setLanguage('fr');

    expect(applied.last, 'es');
    expect(coordinator.languageCode.value, 'es');
  });

  test('translate resuelve claves de cualquier paquete registrado', () {
    coordinator.register('plugin_a', (_) {}, translate: (key) => key == 'pluginA.title' ? 'Plugin A' : null);

    expect(coordinator.translate('pluginA.title'), 'Plugin A');
    expect(coordinator.translate('common.cancel'), 'Cancelar');
    expect(coordinator.translate('common'), 'common', reason: 'una sección no es un texto');
    expect(coordinator.translate('desconocida.clave'), 'desconocida.clave');

    coordinator.setLanguage('en');
    expect(coordinator.translate('common.cancel'), 'Cancel');

    coordinator.register('plugin_a', (_) {});
    expect(coordinator.translate('pluginA.title'), 'pluginA.title');
  });

  test('resolveLanguage elige el primer idioma soportado del dispositivo', () {
    expect(
      LocalizationCoordinator.resolveLanguage(const [Locale('fr'), Locale('en', 'US'), Locale('es')]),
      'en',
    );
    expect(LocalizationCoordinator.resolveLanguage(const [Locale('de')]), 'es');
  });
}
