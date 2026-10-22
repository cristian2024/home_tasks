import 'package:plugin_item_tracker/plugin_item_tracker.dart';

/// Objetos de ejemplo para recorrer los criterios de aceptación a mano.
class DemoData {
  const DemoData(this._dependencies);

  final ItemTrackerDependencies _dependencies;

  /// Códigos sugeridos y qué deberían producir (genera un QR con el texto o
  /// escríbelo en el modo Código).
  static const codes = [
    ('QR-123', 'QR de «Caja A»: abre su detalle (AC-03).'),
    ('UNKNOWN-99', 'QR sin registrar: ofrece crear o asociar (AC-04).'),
    ('QR-BED', 'QR de «Cama». Asocia después una etiqueta NFC a «Cama» (AC-05).'),
    ('049000000443', 'Código de barras de la caja de ropa de invierno.'),
  ];

  /// Crea los objetos que falten. Devuelve cuántos creó.
  Future<int> load() async {
    var created = 0;
    Future<void> create(
      String name, {
      String description = '',
      Map<String, Object?> metadata = const {},
      required ({String rawValue, IdentifierType type}) identifier,
    }) async {
      try {
        await _dependencies.createItem(
          name: name,
          description: description,
          metadata: metadata,
          identifier: identifier,
        );
        created++;
      } on IdentifierAlreadyBoundException {
        // Ya estaba cargado.
      }
    }

    await create('Caja A', identifier: (rawValue: 'QR-123', type: IdentifierType.qr));
    await create('Cama', identifier: (rawValue: 'QR-BED', type: IdentifierType.qr));
    await create(
      'Caja de Almacenamiento Ropa Invierno',
      description: 'Ubicada en el estante superior del armario principal.',
      metadata: {'color_etiqueta': 'Azul', 'peso_kg': 12.5, 'fragil': false},
      identifier: (rawValue: '049000000443', type: IdentifierType.barcode),
    );
    return created;
  }
}
