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

  group('overrideTranslations', () {
    tearDown(() {
      coordinator
        ..overrideTranslations('core_ui', 'es', <String, Object?>{})
        ..overrideTranslations('core_ui', 'en', <String, Object?>{});
    });

    test('los textos reemplazados tienen prioridad y el resto sale del paquete', () {
      coordinator.overrideTranslations('core_ui', 'es', <String, Object?>{
        'common': <String, Object?>{'cancel': 'Descartar', 'unexpected_error': 'Algo falló.'},
      });

      expect(commonStrings.common.cancel, 'Descartar');
      expect(commonStrings.common.unexpectedError, 'Algo falló.');
      expect(commonStrings.common.save, 'Guardar');
      expect(coordinator.translate('common.cancel'), 'Descartar');
    });

    test('cada idioma tiene sus reemplazos y se mantienen al cambiar de idioma', () {
      coordinator
        ..overrideTranslations('core_ui', 'en', <String, Object?>{
          'common': <String, Object?>{'cancel': 'Dismiss'},
        })
        ..setLanguage('en');
      expect(commonStrings.common.cancel, 'Dismiss');

      coordinator.setLanguage('es');
      expect(commonStrings.common.cancel, 'Cancelar');

      coordinator.setLanguage('en');
      expect(commonStrings.common.cancel, 'Dismiss');
    });

    test('un mapa vacío quita los reemplazos', () {
      coordinator
        ..overrideTranslations('core_ui', 'es', <String, Object?>{
          'common': <String, Object?>{'cancel': 'Descartar'},
        })
        ..overrideTranslations('core_ui', 'es', <String, Object?>{});

      expect(commonStrings.common.cancel, 'Cancelar');
    });

    test('se aplican al paquete aunque se registre después, y de nuevo al volver a registrarlo', () {
      final List<String> applied = <String>[];
      void record(String code, Map<String, Object?> overrides) => applied.add('$code:${overrides.length}');

      coordinator.overrideTranslations('plugin_a', 'en', <String, Object?>{'title': 'A'});
      expect(applied, isEmpty);

      coordinator.register('plugin_a', (_) {}, override: record);
      expect(applied, <String>['en:1']);

      coordinator.overrideTranslations('plugin_a', 'es', <String, Object?>{'title': 'A', 'subtitle': 'B'});
      expect(applied, <String>['en:1', 'es:2']);

      applied.clear();
      coordinator.register('plugin_a', (_) {}, override: record);
      expect(applied, unorderedEquals(<String>['en:1', 'es:2']));
    });

    test('rechaza idiomas no soportados', () {
      expect(
        () => coordinator.overrideTranslations('core_ui', 'fr', <String, Object?>{}),
        throwsArgumentError,
      );
    });
  });

  test('resolveLanguage elige el primer idioma soportado del dispositivo', () {
    expect(
      LocalizationCoordinator.resolveLanguage(const [Locale('fr'), Locale('en', 'US'), Locale('es')]),
      'en',
    );
    expect(LocalizationCoordinator.resolveLanguage(const [Locale('de')]), 'es');
  });
}
