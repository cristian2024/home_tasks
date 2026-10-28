import 'package:core_hardware/core_hardware.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/household_item.dart';
import '../../domain/entities/item_event.dart';
import '../../domain/entities/physical_identifier.dart';
import '../../domain/errors/item_tracker_exception.dart';
import '../../i18n/strings.g.dart';

ItemTrackerTranslations get _t => itemTrackerStrings;

String identifierTypeLabel(IdentifierType type) => switch (type) {
      IdentifierType.qr => _t.itemTracker.identifierTypes.qr,
      IdentifierType.barcode => _t.itemTracker.identifierTypes.barcode,
      IdentifierType.nfc => _t.itemTracker.identifierTypes.nfc,
    };

IdentifierType identifierTypeFromScan(ScanType type) => switch (type) {
      ScanType.qr => IdentifierType.qr,
      ScanType.barcode => IdentifierType.barcode,
      ScanType.nfc => IdentifierType.nfc,
    };

/// Texto localizado de un evento. Los técnicos se componen a partir de sus
/// datos (§9.4); las notas se muestran tal cual.
({String title, String? subtitle}) describeEvent(ItemEvent event) {
  final ItemTrackerTranslations$itemTracker$events$es events = _t.itemTracker.events;
  return switch (event.kind) {
    ItemEventKind.created => (title: events.created(name: event.title), subtitle: null),
    ItemEventKind.updated => (
        title: events.updated(
          fields: event.description
              .split(',')
              .map(
                (String field) => switch (field) {
                  'name' => events.fieldName,
                  'description' => events.fieldDescription,
                  'metadata' => events.fieldMetadata,
                  _ => field,
                },
              )
              .join(', '),
        ),
        subtitle: null,
      ),
    ItemEventKind.identifierBound => (
        title: events.identifierBound(
          type: identifierTypeLabel(IdentifierType.values.asNameMap()[event.title] ?? IdentifierType.qr),
          value: event.description,
        ),
        subtitle: null,
      ),
    ItemEventKind.identifierUnbound => (
        title: events.identifierUnbound(
          type: identifierTypeLabel(IdentifierType.values.asNameMap()[event.title] ?? IdentifierType.qr),
          value: event.description,
        ),
        subtitle: null,
      ),
    ItemEventKind.moved => (
        title: event.title.isEmpty ? events.movedOut : events.moved(name: event.title),
        subtitle: null,
      ),
    ItemEventKind.childAdded => (title: events.childAdded(name: event.title), subtitle: null),
    ItemEventKind.childRemoved => (title: events.childRemoved(name: event.title), subtitle: null),
    ItemEventKind.note => (title: event.title, subtitle: event.description.isEmpty ? null : event.description),
  };
}

/// Ruta de contenedores para mostrar, p. ej. "Mueble › Organizador".
String formatItemPath(Iterable<HouseholdItem> path) => path.map((HouseholdItem item) => item.name).join(' › ');

/// Mensaje de un error de validación para mostrar junto al campo.
String validationMessage(ItemValidationException error) {
  final ItemTrackerTranslations$itemTracker$errors$es errors = _t.itemTracker.errors;
  final String key = error.detail ?? '';
  return switch ((error.field, error.reason)) {
    (_, ValidationReason.empty) => errors.required,
    (_, ValidationReason.tooManyEntries) => errors.metadataTooMany,
    (ValidationField.metadata, ValidationReason.invalidFormat) => errors.metadataKeyInvalid(key: key),
    (ValidationField.metadata, _) => errors.metadataValueInvalid(key: key),
    (ValidationField.identifierValue, ValidationReason.invalidFormat) => errors.identifierInvalid,
    (_, ValidationReason.tooLong) => errors.tooLong,
    (_, _) => errors.unexpected,
  };
}

/// Mensaje general de cualquier error del plugin.
String errorMessage(Object error, {String? currentItemId}) {
  final ItemTrackerTranslations$itemTracker$errors$es errors = _t.itemTracker.errors;
  return switch (error) {
    ItemNotFoundException() => errors.itemNotFound,
    IdentifierNotFoundException() => errors.identifierNotFound,
    ItemContainmentCycleException() => errors.containmentCycle,
    ItemContainmentTooDeepException(:final int maxDepth) => errors.containmentTooDeep(max: maxDepth),
    IdentifierAlreadyBoundException(:final String boundItemId) =>
      boundItemId == currentItemId ? errors.alreadyBoundSame : errors.alreadyBoundOther,
    final ItemValidationException validation => validationMessage(validation),
    _ => errors.unexpected,
  };
}

/// Fecha y hora locales de un instante UTC, con el formato del idioma activo.
String formatTimestamp(BuildContext context, DateTime utc) {
  final DateTime local = utc.toLocal();
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(local)} · '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
