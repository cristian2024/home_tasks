import 'package:task_list_domain/task_list_domain.dart';
import 'package:test/test.dart';

void main() {
  test('valida el título', () {
    expect(TaskValidator.title('  Sacar la basura '), 'Sacar la basura');
    expect(TaskValidator.title('a' * 100), hasLength(100));
    expect(() => TaskValidator.title('   '), throwsA(_validation(TaskValidationField.title, TaskValidationReason.empty)));
    expect(() => TaskValidator.title('a' * 101), throwsA(_validation(TaskValidationField.title, TaskValidationReason.tooLong)));
  });

  test('valida el nombre de una categoría', () {
    expect(TaskValidator.categoryName(' Jardín '), 'Jardín');
    expect(
      () => TaskValidator.categoryName(''),
      throwsA(_validation(TaskValidationField.categoryName, TaskValidationReason.empty)),
    );
    expect(
      () => TaskValidator.categoryName('a' * 41),
      throwsA(_validation(TaskValidationField.categoryName, TaskValidationReason.tooLong)),
    );
  });

  test('los errores se describen con sus datos', () {
    expect(const TaskNotFoundException('t1').toString(), 'TaskNotFoundException(t1)');
    expect(const TaskCategoryNotFoundException('c1').toString(), 'TaskCategoryNotFoundException(c1)');
    expect(const TaskCategoryNameTakenException('Jardín').toString(), 'TaskCategoryNameTakenException(Jardín)');
    expect(
      const TaskValidationException(TaskValidationField.title, TaskValidationReason.empty).toString(),
      'TaskValidationException(title, empty)',
    );
  });
}

Matcher _validation(TaskValidationField field, TaskValidationReason reason) => isA<TaskValidationException>()
    .having((TaskValidationException e) => e.field, 'field', field)
    .having((TaskValidationException e) => e.reason, 'reason', reason);
