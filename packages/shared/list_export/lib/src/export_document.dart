import 'package:equatable/equatable.dart';

/// Lista lista para exportar. Los textos llegan ya traducidos: los
/// formateadores solo les dan forma.
class ExportDocument extends Equatable {
  const ExportDocument({required this.title, this.sections = const <ExportSection>[], this.footer});

  final String title;
  final List<ExportSection> sections;

  /// Texto final opcional, p. ej. la fecha de exportación.
  final String? footer;

  /// Si no tiene ninguna entrada.
  bool get isEmpty => sections.every((ExportSection section) => section.entries.isEmpty);

  @override
  List<Object?> get props => <Object?>[title, sections, footer];
}

/// Grupo de entradas, p. ej. una categoría. Sin [heading], las entradas van
/// sin encabezado.
class ExportSection extends Equatable {
  const ExportSection({this.heading, required this.entries});

  final String? heading;
  final List<ExportEntry> entries;

  @override
  List<Object?> get props => <Object?>[heading, entries];
}

/// Una línea de la lista.
class ExportEntry extends Equatable {
  const ExportEntry({required this.text, this.detail, this.emphasized = false});

  final String text;

  /// Información adicional que va tras el texto, p. ej. la cantidad.
  final String? detail;

  /// Se resalta (p. ej. lo urgente).
  final bool emphasized;

  @override
  List<Object?> get props => <Object?>[text, detail, emphasized];
}
