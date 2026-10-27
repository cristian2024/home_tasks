import 'dart:io';

import 'src/architecture_rules.dart';

/// Verifica las reglas de importación del §5.2 de `specs/app_spec.md`.
///
/// Uso (desde la raíz del monorepo): `dart run tool/verify_architecture.dart`
void main() {
  final List<ArchitectureViolation> violations = findViolations(Directory.current.absolute);
  if (violations.isEmpty) {
    stdout.writeln('Arquitectura OK: sin violaciones de importación.');
    return;
  }
  stderr.writeln('Se encontraron ${violations.length} violaciones de arquitectura:');
  for (final ArchitectureViolation violation in violations) {
    stderr.writeln('  $violation');
  }
  exitCode = 1;
}
