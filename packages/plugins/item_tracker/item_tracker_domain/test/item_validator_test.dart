import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:test/test.dart';

import 'helpers/domain_fixtures.dart';

void main() {
  group('name', () {
    test('recorta espacios y exige contenido', () {
      expect(ItemValidator.name('  Caja A  '), 'Caja A');
      expect(() => ItemValidator.name('   '), throwsValidation(ValidationField.name, ValidationReason.empty));
    });

    test('admite hasta 120 caracteres', () {
      expect(ItemValidator.name('a' * 120), hasLength(120));
      expect(() => ItemValidator.name('a' * 121), throwsValidation(ValidationField.name, ValidationReason.tooLong));
    });
  });

  test('description es opcional y admite hasta 2000 caracteres', () {
    expect(ItemValidator.description('  '), '');
    expect(ItemValidator.description('a' * 2000), hasLength(2000));
    expect(
      () => ItemValidator.description('a' * 2001),
      throwsValidation(ValidationField.description, ValidationReason.tooLong),
    );
  });

  test('eventTitle es obligatorio y eventDescription opcional', () {
    expect(ItemValidator.eventTitle(' Mudanza '), 'Mudanza');
    expect(() => ItemValidator.eventTitle(''), throwsValidation(ValidationField.eventTitle, ValidationReason.empty));
    expect(
      () => ItemValidator.eventTitle('a' * 121),
      throwsValidation(ValidationField.eventTitle, ValidationReason.tooLong),
    );
    expect(ItemValidator.eventDescription(''), '');
    expect(
      () => ItemValidator.eventDescription('a' * 2001),
      throwsValidation(ValidationField.eventDescription, ValidationReason.tooLong),
    );
  });

  group('identifierValue', () {
    test('conserva los espacios y las URLs como texto', () {
      expect(ItemValidator.identifierValue(' BOX 1 '), ' BOX 1 ');
      expect(ItemValidator.identifierValue('https://x.y'), 'https://x.y');
    });

    test('rechaza vacío, más de 2048 caracteres y caracteres de control', () {
      expect(
        () => ItemValidator.identifierValue(''),
        throwsValidation(ValidationField.identifierValue, ValidationReason.empty),
      );
      expect(ItemValidator.identifierValue('a' * 2048), hasLength(2048));
      expect(
        () => ItemValidator.identifierValue('a' * 2049),
        throwsValidation(ValidationField.identifierValue, ValidationReason.tooLong),
      );
      expect(
        () => ItemValidator.identifierValue('QR\n1'),
        throwsValidation(ValidationField.identifierValue, ValidationReason.invalidFormat),
      );
    });
  });
}
