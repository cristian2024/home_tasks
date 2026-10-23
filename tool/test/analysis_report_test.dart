import 'package:test/test.dart';

import '../src/analysis_report.dart';

void main() {
  const String root = '/repo';
  const String output = '''
WARNING|LINT|ALWAYS_SPECIFY_TYPES|/repo/packages/plugins/plugin_a/lib/a.dart|2|3|3|Missing type annotation.
WARNING|LINT|ALWAYS_SPECIFY_TYPES|/repo/packages/plugins/plugin_a/test/a_test.dart|5|7|3|Missing type annotation.
WARNING|LINT|ALWAYS_SPECIFY_TYPES|/repo/apps/app/lib/main.dart|1|1|3|Missing type annotation.
INFO|LINT|AVOID_PRINT|/repo/tool/x.dart|3|3|5|Don't invoke 'print' in production code.
ERROR|COMPILE_TIME_ERROR|UNDEFINED_IDENTIFIER|/repo/packages/design_system/example/lib/main.dart|4|1|1|Undefined name 'a\\|b'.
Analyzing home_tasks...
''';

  test('lee los diagnósticos y descarta las líneas que no lo son', () {
    final AnalyzerIssue issue = AnalyzerIssue.tryParse(
      'ERROR|COMPILE_TIME_ERROR|UNDEFINED_IDENTIFIER|/repo/a.dart|4|1|1|Undefined name \'a\\|b\'.',
    )!;

    expect(issue.severity, 'ERROR');
    expect(issue.code, 'undefined_identifier');
    expect(issue.file, '/repo/a.dart');
    expect(issue.line, 4);
    expect(issue.column, 1);
    expect(issue.message, "Undefined name 'a|b'.");
    expect(issue.toString(), "error - /repo/a.dart:4:1 - Undefined name 'a|b'. - undefined_identifier");
    expect(AnalyzerIssue.tryParse('Analyzing home_tasks...'), isNull);
    expect(AnalyzerIssue.tryParse('A|B|C|D|x|1|1|msg'), isNull);
  });

  test('separa lo tolerado de lo que bloquea, incluidos los infos', () {
    final AnalysisReport report = AnalysisReport.fromMachineOutput(
      output,
      toleratedCodes: <String>{'always_specify_types'},
    );

    expect(report.tolerated, hasLength(3));
    expect(report.blocking.map((AnalyzerIssue issue) => issue.code), <String>['avoid_print', 'undefined_identifier']);
  });

  test('sin reglas toleradas todo bloquea', () {
    final AnalysisReport report = AnalysisReport.fromMachineOutput(output, toleratedCodes: <String>{});

    expect(report.tolerated, isEmpty);
    expect(report.blocking, hasLength(5));
  });

  test('cuenta lo tolerado por proyecto, de más a menos', () {
    final AnalysisReport report = AnalysisReport.fromMachineOutput(
      output,
      toleratedCodes: <String>{'always_specify_types'},
    );

    expect(report.toleratedByCode(root: root), <String, Map<String, int>>{
      'always_specify_types': <String, int>{'packages/plugins/plugin_a': 2, 'apps/app': 1},
    });
  });

  test('identifica el proyecto de cada archivo', () {
    String project(String file) => AnalysisReport.projectOf(file, root: '$root/');

    expect(project('/repo/packages/core/core_di/lib/a.dart'), 'packages/core/core_di');
    expect(project('/repo/packages/design_system/example/lib/main.dart'), 'packages/design_system');
    expect(project('/repo/apps/app/lib/main.dart'), 'apps/app');
    expect(project('/repo/tool/analyze.dart'), 'tool');
    expect(project('/repo/pubspec.yaml'), 'pubspec.yaml');
  });
}
