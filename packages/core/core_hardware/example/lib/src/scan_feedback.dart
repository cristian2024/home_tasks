import 'package:core_hardware/core_hardware.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

String describeScanError(ScanException error) => switch (error.code) {
  ScanErrorCode.permissionDenied => 'Permiso de cámara denegado.',
  ScanErrorCode.hardwareUnsupported =>
    'Este dispositivo no tiene el hardware necesario.',
  ScanErrorCode.hardwareDisabled =>
    'El hardware está desactivado. Actívalo en Ajustes.',
  ScanErrorCode.invalidValue => 'El código leído no es válido.',
  ScanErrorCode.tagNotWritable => 'El tag no admite escritura.',
  ScanErrorCode.cancelled => 'Lectura cancelada.',
  ScanErrorCode.unknown =>
    'Error inesperado: ${error.message ?? error.cause ?? ''}',
};

String describeScanType(ScanType type) => switch (type) {
  ScanType.qr => 'QR',
  ScanType.barcode => 'Código de barras',
  ScanType.nfc => 'NFC',
};

/// Anuncia la lectura a TalkBack / VoiceOver (spec §14.4).
void announceScan(BuildContext context, PhysicalScanResult result) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    '${describeScanType(result.type)} leído: ${result.rawValue}',
    Directionality.of(context),
  );
}

class ScanResultsList extends StatelessWidget {
  const ScanResultsList({super.key, required this.results});

  final List<PhysicalScanResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(child: Text('Sin lecturas todavía.'));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          leading: Icon(
            result.type == ScanType.nfc ? Icons.nfc : Icons.qr_code,
          ),
          // Texto no confiable: se muestra literal y nunca se abre (§8.2).
          title: SelectableText(result.rawValue, maxLines: 3),
          subtitle: Text(
            '${describeScanType(result.type)} · ${result.scannedAt.toIso8601String()}',
          ),
        );
      },
    );
  }
}

class StatusMessage extends StatelessWidget {
  const StatusMessage({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
