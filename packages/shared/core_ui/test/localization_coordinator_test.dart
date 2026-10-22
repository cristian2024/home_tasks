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

  test('resolveLanguage elige el primer idioma soportado del dispositivo', () {
    expect(
      LocalizationCoordinator.resolveLanguage(const [Locale('fr'), Locale('en', 'US'), Locale('es')]),
      'en',
    );
    expect(LocalizationCoordinator.resolveLanguage(const [Locale('de')]), 'es');
  });
}
