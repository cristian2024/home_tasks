import 'dart:io';

import 'src/analysis_report.dart';

/// Reglas que se están adoptando poco a poco: se avisan, pero no hacen fallar
/// el análisis. Cuando queden pocos casos, se quitan de aquí y pasan a ser
/// obligatorias.
const Set<String> toleratedCodes = <String>{};

/// Análisis estático del workspace. Equivale a `dart analyze --fatal-infos .`
/// salvo por [toleratedCodes].
///
/// Uso (desde la raíz del monorepo): `dart run tool/analyze.dart`
Future<void> main() async {
  final String root = Directory.current.absolute.path;
  final ProcessResult result = await Process.run('dart', <String>['analyze', '--format=machine', '.']);
  final String output = '${result.stdout}${result.stderr}';
  final AnalysisReport report = AnalysisReport.fromMachineOutput(output, toleratedCodes: toleratedCodes);

  // Sin diagnósticos, un código distinto de 0 es un fallo del propio analizador.
  if (result.exitCode != 0 && report.blocking.isEmpty && report.tolerated.isEmpty) {
    stderr.write(output);
    exitCode = result.exitCode;
    return;
  }

  for (final MapEntry<String, Map<String, int>> entry in report.toleratedByCode(root: root).entries) {
    final int total = entry.value.values.fold(0, (int sum, int count) => sum + count);
    stdout.writeln('Aviso: $total casos de ${entry.key} (no bloquea):');
    for (final MapEntry<String, int> project in entry.value.entries) {
      stdout.writeln('  ${project.value.toString().padLeft(5)}  ${project.key}');
    }
  }

  if (report.blocking.isEmpty) {
    stdout.writeln('Análisis OK: sin problemas bloqueantes.');
    return;
  }
  stderr.writeln('Se encontraron ${report.blocking.length} problemas:');
  for (final AnalyzerIssue issue in report.blocking) {
    stderr.writeln('  $issue');
  }
  exitCode = 1;
}
