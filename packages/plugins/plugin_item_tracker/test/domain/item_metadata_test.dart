import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  test('acepta texto, enteros, decimales y booleanos (ejemplo del §9.3)', () {
    final metadata = ItemMetadata({'color_etiqueta': 'Azul', 'peso_kg': 12.5, 'unidades': 3, 'fragil': false});

    expect(metadata.values, {'color_etiqueta': 'Azul', 'peso_kg': 12.5, 'unidades': 3, 'fragil': false});
    expect(metadata.isEmpty, isFalse);
    expect(const ItemMetadata.empty().isEmpty, isTrue);
  });

  test('es inmodificable e igual por valor', () {
    final metadata = ItemMetadata({'a': 1});

    expect(() => metadata.values['b'] = 2, throwsUnsupportedError);
    expect(metadata, ItemMetadata({'a': 1}));
    expect(metadata, isNot(ItemMetadata({'a': 2})));
    expect(metadata.toString(), contains('a'));
  });

  test('rechaza claves que no son snake_case', () {
    for (final key in ['Color', 'peso-kg', '1peso', '', 'peso kg', '_x']) {
      expect(() => ItemMetadata({key: 1}), throwsValidation(ValidationField.metadata, ValidationReason.invalidFormat));
    }
  });

  test('rechaza claves de más de 64 caracteres', () {
    expect(ItemMetadata({'a' * 64: 1}).values, hasLength(1));
    expect(() => ItemMetadata({'a' * 65: 1}), throwsValidation(ValidationField.metadata, ValidationReason.tooLong));
  });

  test('rechaza textos de más de 500 caracteres', () {
    expect(ItemMetadata({'nota': 'x' * 500}).values, hasLength(1));
    expect(() => ItemMetadata({'nota': 'x' * 501}), throwsValidation(ValidationField.metadata, ValidationReason.tooLong));
  });

  test('rechaza más de 50 entradas', () {
    Map<String, Object?> entries(int n) => {for (var i = 0; i < n; i++) 'k$i': i};

    expect(ItemMetadata(entries(50)).values, hasLength(50));
    expect(() => ItemMetadata(entries(51)), throwsValidation(ValidationField.metadata, ValidationReason.tooLong));
  });

  test('rechaza valores no escalares, nulos y números no finitos', () {
    for (final value in [null, <int>[1], <String, int>{'a': 1}, double.nan, double.infinity, DateTime(2026)]) {
      expect(
        () => ItemMetadata({'dato': value}),
        throwsValidation(ValidationField.metadata, ValidationReason.unsupportedValue),
      );
    }
  });

  test('el error indica la clave que falló', () {
    expect(
      () => ItemMetadata({'ok': 1, 'Mal': 2}),
      throwsA(isA<ItemValidationException>().having((e) => e.detail, 'detail', 'Mal')),
    );
  });
}
