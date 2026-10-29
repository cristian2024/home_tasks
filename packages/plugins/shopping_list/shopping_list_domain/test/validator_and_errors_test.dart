import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:test/test.dart';

Matcher _invalid(ShoppingValidationField field, ShoppingValidationReason reason) =>
    throwsA(isA<ShoppingValidationException>()
        .having((ShoppingValidationException e) => e.field, 'field', field)
        .having((ShoppingValidationException e) => e.reason, 'reason', reason));

void main() {
  group('ShoppingValidator', () {
    test('recorta los textos y los devuelve', () {
      expect(ShoppingValidator.name('  Huevos '), 'Huevos');
      expect(ShoppingValidator.notes(' camperos '), 'camperos');
      expect(ShoppingValidator.quantity(' 2 docenas '), '2 docenas');
      expect(ShoppingValidator.categoryName(' Comida '), 'Comida');
      expect(ShoppingValidator.notes('  '), '');
    });

    test('el nombre y el de la categoría son obligatorios', () {
      expect(() => ShoppingValidator.name(' '), _invalid(ShoppingValidationField.name, ShoppingValidationReason.empty));
      expect(
        () => ShoppingValidator.categoryName(''),
        _invalid(ShoppingValidationField.categoryName, ShoppingValidationReason.empty),
      );
    });

    test('rechaza textos demasiado largos', () {
      expect(
        () => ShoppingValidator.name('a' * 121),
        _invalid(ShoppingValidationField.name, ShoppingValidationReason.tooLong),
      );
      expect(
        () => ShoppingValidator.notes('a' * 2001),
        _invalid(ShoppingValidationField.notes, ShoppingValidationReason.tooLong),
      );
      expect(
        () => ShoppingValidator.quantity('a' * 41),
        _invalid(ShoppingValidationField.quantity, ShoppingValidationReason.tooLong),
      );
      expect(
        () => ShoppingValidator.categoryName('a' * 41),
        _invalid(ShoppingValidationField.categoryName, ShoppingValidationReason.tooLong),
      );
      expect(ShoppingValidator.name('a' * 120), hasLength(120));
    });

    test('normalize ignora mayúsculas y espacios de sobra', () {
      expect(ShoppingValidator.normalize('  Papel   Higiénico '), 'papel higiénico');
    });
  });

  test('los errores describen su dato', () {
    expect(const ShoppingItemNotFoundException('i1').toString(), 'ShoppingItemNotFoundException(i1)');
    expect(const ShoppingCategoryNotFoundException('c1').toString(), 'ShoppingCategoryNotFoundException(c1)');
    expect(const ShoppingCategoryNameTakenException('Comida').toString(), 'ShoppingCategoryNameTakenException(Comida)');
    expect(
      const ShoppingValidationException(ShoppingValidationField.name, ShoppingValidationReason.empty).toString(),
      'ShoppingValidationException(name, empty)',
    );
  });
}
