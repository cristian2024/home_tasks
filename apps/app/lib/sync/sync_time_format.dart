import 'package:flutter/material.dart';

/// Fecha y hora locales de [utc], en el formato corto del idioma de la app.
String formatSyncTime(BuildContext context, DateTime utc) {
  final MaterialLocalizations l10n = MaterialLocalizations.of(context);
  final DateTime local = utc.toLocal();
  return '${l10n.formatShortDate(local)} ${l10n.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
