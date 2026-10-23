/// Diagnóstico de `dart analyze --format=machine`.
class AnalyzerIssue {
  final String severity;
  final String code;
  final String file;
  final int line;
  final int column;
  final String message;

  const AnalyzerIssue({
    required this.severity,
    required this.code,
    required this.file,
    required this.line,
    required this.column,
    required this.message,
  });

  /// Lee una línea `SEVERIDAD|TIPO|CÓDIGO|ARCHIVO|LÍNEA|COLUMNA|LONGITUD|MENSAJE`.
  /// Devuelve `null` si la línea no es un diagnóstico.
  static AnalyzerIssue? tryParse(String line) {
    final List<String> fields = line.split('|');
    if (fields.length < 8) {
      return null;
    }
    final int? lineNumber = int.tryParse(fields[4]);
    final int? column = int.tryParse(fields[5]);
    if (lineNumber == null || column == null) {
      return null;
    }
    return AnalyzerIssue(
      severity: fields[0],
      code: fields[2].toLowerCase(),
      file: fields[3],
      line: lineNumber,
      column: column,
      // El mensaje puede contener '|' (escapado como '\|').
      message: fields.sublist(7).join('|').replaceAll(r'\|', '|'),
    );
  }

  @override
  String toString() => '${severity.toLowerCase()} - $file:$line:$column - $message - $code';
}

/// Resultado del análisis separado en lo que bloquea y lo que solo se avisa.
class AnalysisReport {
  /// Diagnósticos que hacen fallar el análisis (equivale a `--fatal-infos`).
  final List<AnalyzerIssue> blocking;

  /// Diagnósticos de reglas en adopción gradual: se cuentan pero no fallan.
  final List<AnalyzerIssue> tolerated;

  const AnalysisReport({required this.blocking, required this.tolerated});

  factory AnalysisReport.fromMachineOutput(String output, {required Set<String> toleratedCodes}) {
    final List<AnalyzerIssue> blocking = <AnalyzerIssue>[];
    final List<AnalyzerIssue> tolerated = <AnalyzerIssue>[];
    for (final String line in output.split('\n')) {
      final AnalyzerIssue? issue = AnalyzerIssue.tryParse(line.trim());
      if (issue == null) {
        continue;
      }
      (toleratedCodes.contains(issue.code) ? tolerated : blocking).add(issue);
    }
    return AnalysisReport(blocking: blocking, tolerated: tolerated);
  }

  /// Avisos tolerados por código y, dentro de cada uno, por proyecto
  /// (`apps/<app>`, `packages/<grupo>/<paquete>`, `tool`…), de más a menos.
  Map<String, Map<String, int>> toleratedByCode({required String root}) {
    final Map<String, Map<String, int>> counts = <String, Map<String, int>>{};
    for (final AnalyzerIssue issue in tolerated) {
      final Map<String, int> byProject = counts.putIfAbsent(issue.code, () => <String, int>{});
      final String project = projectOf(issue.file, root: root);
      byProject[project] = (byProject[project] ?? 0) + 1;
    }
    return <String, Map<String, int>>{
      for (final MapEntry<String, Map<String, int>> entry in counts.entries)
        entry.key: Map<String, int>.fromEntries(
          entry.value.entries.toList()..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value - a.value),
        ),
    };
  }

  /// Proyecto del monorepo al que pertenece [file].
  static String projectOf(String file, {required String root}) {
    final String prefix = root.endsWith('/') ? root : '$root/';
    final String relative = file.startsWith(prefix) ? file.substring(prefix.length) : file;
    final List<String> segments = relative.split('/');
    if (segments.first == 'packages' && segments.length > 2 && segments[1] == 'design_system') {
      return 'packages/design_system';
    }
    final int depth = switch (segments.first) {
      'packages' => 3,
      'apps' => 2,
      _ => 1,
    };
    return segments.length > depth ? segments.take(depth).join('/') : segments.first;
  }
}
