///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class ItemTrackerTranslationsEn with BaseTranslations<ItemTrackerLocale, ItemTrackerTranslations> implements ItemTrackerTranslations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [ItemTrackerLocale.build] is preferred.
	ItemTrackerTranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<ItemTrackerLocale, ItemTrackerTranslations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: ItemTrackerLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<ItemTrackerLocale, ItemTrackerTranslations> _meta;
	@override TranslationMetadata<ItemTrackerLocale, ItemTrackerTranslations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key);

	late final ItemTrackerTranslationsEn _root = this; // ignore: unused_field

	@override 
	ItemTrackerTranslationsEn $copyWith({TranslationMetadata<ItemTrackerLocale, ItemTrackerTranslations>? meta}) => ItemTrackerTranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _ItemTrackerTranslations$itemTracker$en itemTracker = _ItemTrackerTranslations$itemTracker$en._(_root);
}

// Path: itemTracker
class _ItemTrackerTranslations$itemTracker$en implements ItemTrackerTranslations$itemTracker$es {
	_ItemTrackerTranslations$itemTracker$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Item Tracker';
	@override String get description => 'Identify your belongings with QR codes, barcodes or NFC tags.';
	@override late final _ItemTrackerTranslations$itemTracker$dashboard$en dashboard = _ItemTrackerTranslations$itemTracker$dashboard$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$identifierTypes$en identifierTypes = _ItemTrackerTranslations$itemTracker$identifierTypes$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$scan$en scan = _ItemTrackerTranslations$itemTracker$scan$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$notFound$en notFound = _ItemTrackerTranslations$itemTracker$notFound$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$list$en list = _ItemTrackerTranslations$itemTracker$list$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$detail$en detail = _ItemTrackerTranslations$itemTracker$detail$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$events$en events = _ItemTrackerTranslations$itemTracker$events$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$form$en form = _ItemTrackerTranslations$itemTracker$form$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$associate$en associate = _ItemTrackerTranslations$itemTracker$associate$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$addEvent$en addEvent = _ItemTrackerTranslations$itemTracker$addEvent$en._(_root);
	@override late final _ItemTrackerTranslations$itemTracker$errors$en errors = _ItemTrackerTranslations$itemTracker$errors$en._(_root);
}

// Path: itemTracker.dashboard
class _ItemTrackerTranslations$itemTracker$dashboard$en implements ItemTrackerTranslations$itemTracker$dashboard$es {
	_ItemTrackerTranslations$itemTracker$dashboard$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get scan => 'Scan';
	@override String get items => 'View items';
	@override String itemsCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'No items registered yet',
		one: '1 item registered',
		other: '${n} items registered',
	);
}

// Path: itemTracker.identifierTypes
class _ItemTrackerTranslations$itemTracker$identifierTypes$en implements ItemTrackerTranslations$itemTracker$identifierTypes$es {
	_ItemTrackerTranslations$itemTracker$identifierTypes$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get qr => 'QR';
	@override String get barcode => 'Barcode';
	@override String get nfc => 'NFC';
}

// Path: itemTracker.scan
class _ItemTrackerTranslations$itemTracker$scan$en implements ItemTrackerTranslations$itemTracker$scan$es {
	_ItemTrackerTranslations$itemTracker$scan$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Scan';
	@override String get modeLabel => 'Identification mode';
	@override String get modeCamera => 'Camera';
	@override String get modeNfc => 'NFC';
	@override String get modeManual => 'Code';
	@override String get promptCamera => 'Point at the QR code or barcode.';
	@override String get promptNfc => 'Tap “Read tag” and hold the NFC tag near the phone.';
	@override String get nfcStart => 'Read tag';
	@override String get nfcCancel => 'Cancel reading';
	@override String get nfcWaiting => 'Hold the NFC tag near the phone…';
	@override String get manualLabel => 'Code';
	@override String get manualHint => 'Type the code exactly as shown';
	@override String get typeLabel => 'Identifier type';
	@override String get manualSubmit => 'Search';
	@override String get lookingUp => 'Looking up the item…';
	@override String readAnnouncement({required Object type, required Object value}) => '${type} read: ${value}';
	@override String get cameraPermissionTitle => 'Camera access needed';
	@override String get cameraPermissionMessage => 'Allow camera access to scan codes, or type the code instead.';
	@override String get cameraPermanentlyDeniedMessage => 'Camera access is denied. Enable it in the app Settings or type the code instead.';
	@override String get cameraRestrictedMessage => 'The system does not allow using the camera on this device. Type the code instead.';
	@override String get grantPermission => 'Allow access';
	@override String get openSettings => 'Open Settings';
	@override String get useManual => 'Type the code';
	@override String get nfcUnsupportedTitle => 'This device has no NFC';
	@override String get nfcUnsupportedMessage => 'You can identify the item with the camera or by typing the code.';
	@override String get nfcDisabledTitle => 'NFC is turned off';
	@override String get nfcDisabledMessage => 'Turn it on in the system Settings and check again.';
	@override String get checkAgain => 'Check again';
	@override String get cameraError => 'The camera could not be used. Type the code instead.';
	@override String get readError => 'The identifier could not be read. Please try again.';
	@override String get readCancelled => 'Reading cancelled.';
}

// Path: itemTracker.notFound
class _ItemTrackerTranslations$itemTracker$notFound$en implements ItemTrackerTranslations$itemTracker$notFound$es {
	_ItemTrackerTranslations$itemTracker$notFound$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Unregistered identifier';
	@override String message({required Object type}) => 'This ${type} is not linked to any item.';
	@override String get create => 'Create new item';
	@override String get associate => 'Link to an existing item';
}

// Path: itemTracker.list
class _ItemTrackerTranslations$itemTracker$list$en implements ItemTrackerTranslations$itemTracker$list$es {
	_ItemTrackerTranslations$itemTracker$list$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Items';
	@override String get search => 'Search by name';
	@override String get emptyTitle => 'No items yet';
	@override String get emptyMessage => 'Scan a code to register the first one.';
	@override String get noResults => 'No items match the search.';
	@override String get create => 'Create item';
}

// Path: itemTracker.detail
class _ItemTrackerTranslations$itemTracker$detail$en implements ItemTrackerTranslations$itemTracker$detail$es {
	_ItemTrackerTranslations$itemTracker$detail$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Item details';
	@override String get missingTitle => 'Item not found';
	@override String get missingMessage => 'It may have been removed.';
	@override String get edit => 'Edit item';
	@override String get addEvent => 'Add note';
	@override String get metadata => 'Additional data';
	@override String get identifiers => 'Identifiers';
	@override String get noIdentifiers => 'No linked identifiers.';
	@override String get history => 'History';
	@override String eventsCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'No events',
		one: '1 event recorded',
		other: '${n} events recorded',
	);
	@override String get yes => 'Yes';
	@override String get no => 'No';
}

// Path: itemTracker.events
class _ItemTrackerTranslations$itemTracker$events$en implements ItemTrackerTranslations$itemTracker$events$es {
	_ItemTrackerTranslations$itemTracker$events$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String created({required Object name}) => 'Item created as “${name}”';
	@override String updated({required Object fields}) => 'Edited: ${fields}';
	@override String identifierBound({required Object type, required Object value}) => '${type} linked: ${value}';
	@override String get fieldName => 'name';
	@override String get fieldDescription => 'description';
	@override String get fieldMetadata => 'additional data';
}

// Path: itemTracker.form
class _ItemTrackerTranslations$itemTracker$form$en implements ItemTrackerTranslations$itemTracker$form$es {
	_ItemTrackerTranslations$itemTracker$form$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get createTitle => 'New item';
	@override String get editTitle => 'Edit item';
	@override String get name => 'Name';
	@override String get description => 'Description';
	@override String get metadata => 'Additional data';
	@override String get metadataHelp => 'Lowercase keys with underscores, for example label_color.';
	@override String get addField => 'Add data';
	@override String removeField({required Object key}) => 'Remove data ${key}';
	@override String get key => 'Key';
	@override String get value => 'Value';
	@override String get valueType => 'Type';
	@override String get typeText => 'Text';
	@override String get typeNumber => 'Number';
	@override String get typeBoolean => 'Yes / No';
	@override String initialIdentifier({required Object type, required Object value}) => 'The ${type} will be linked: ${value}';
	@override String get save => 'Save';
}

// Path: itemTracker.associate
class _ItemTrackerTranslations$itemTracker$associate$en implements ItemTrackerTranslations$itemTracker$associate$es {
	_ItemTrackerTranslations$itemTracker$associate$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Link to an item';
	@override String identifier({required Object type, required Object value}) => '${type}: ${value}';
	@override String get search => 'Search item by name';
	@override String get empty => 'No items match the search.';
	@override String select({required Object name}) => 'Link to ${name}';
	@override String success({required Object name}) => 'Identifier linked to ${name}.';
}

// Path: itemTracker.addEvent
class _ItemTrackerTranslations$itemTracker$addEvent$en implements ItemTrackerTranslations$itemTracker$addEvent$es {
	_ItemTrackerTranslations$itemTracker$addEvent$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Add note';
	@override String get eventTitle => 'Title';
	@override String get eventDescription => 'Description';
	@override String get save => 'Save note';
}

// Path: itemTracker.errors
class _ItemTrackerTranslations$itemTracker$errors$en implements ItemTrackerTranslations$itemTracker$errors$es {
	_ItemTrackerTranslations$itemTracker$errors$en._(this._root);

	final ItemTrackerTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get itemNotFound => 'The item no longer exists.';
	@override String get alreadyBoundOther => 'This identifier is already linked to another item.';
	@override String get alreadyBoundSame => 'This identifier is already linked to this item.';
	@override String get openBoundItem => 'View item';
	@override String get required => 'This field is required.';
	@override String get tooLong => 'The text is too long.';
	@override String get identifierInvalid => 'The code contains invalid characters.';
	@override String metadataKeyInvalid({required Object key}) => 'The key “${key}” is not valid.';
	@override String metadataKeyDuplicated({required Object key}) => 'The key “${key}” is repeated.';
	@override String metadataValueInvalid({required Object key}) => 'The value of “${key}” is not valid.';
	@override String get metadataTooMany => 'There is too much additional data.';
	@override String get numberInvalid => 'Enter a valid number.';
	@override String get unexpected => 'An unexpected error occurred.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on ItemTrackerTranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'itemTracker.title' => 'Item Tracker',
			'itemTracker.description' => 'Identify your belongings with QR codes, barcodes or NFC tags.',
			'itemTracker.dashboard.scan' => 'Scan',
			'itemTracker.dashboard.items' => 'View items',
			'itemTracker.dashboard.itemsCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'No items registered yet', one: '1 item registered', other: '${n} items registered', ), 
			'itemTracker.identifierTypes.qr' => 'QR',
			'itemTracker.identifierTypes.barcode' => 'Barcode',
			'itemTracker.identifierTypes.nfc' => 'NFC',
			'itemTracker.scan.title' => 'Scan',
			'itemTracker.scan.modeLabel' => 'Identification mode',
			'itemTracker.scan.modeCamera' => 'Camera',
			'itemTracker.scan.modeNfc' => 'NFC',
			'itemTracker.scan.modeManual' => 'Code',
			'itemTracker.scan.promptCamera' => 'Point at the QR code or barcode.',
			'itemTracker.scan.promptNfc' => 'Tap “Read tag” and hold the NFC tag near the phone.',
			'itemTracker.scan.nfcStart' => 'Read tag',
			'itemTracker.scan.nfcCancel' => 'Cancel reading',
			'itemTracker.scan.nfcWaiting' => 'Hold the NFC tag near the phone…',
			'itemTracker.scan.manualLabel' => 'Code',
			'itemTracker.scan.manualHint' => 'Type the code exactly as shown',
			'itemTracker.scan.typeLabel' => 'Identifier type',
			'itemTracker.scan.manualSubmit' => 'Search',
			'itemTracker.scan.lookingUp' => 'Looking up the item…',
			'itemTracker.scan.readAnnouncement' => ({required Object type, required Object value}) => '${type} read: ${value}',
			'itemTracker.scan.cameraPermissionTitle' => 'Camera access needed',
			'itemTracker.scan.cameraPermissionMessage' => 'Allow camera access to scan codes, or type the code instead.',
			'itemTracker.scan.cameraPermanentlyDeniedMessage' => 'Camera access is denied. Enable it in the app Settings or type the code instead.',
			'itemTracker.scan.cameraRestrictedMessage' => 'The system does not allow using the camera on this device. Type the code instead.',
			'itemTracker.scan.grantPermission' => 'Allow access',
			'itemTracker.scan.openSettings' => 'Open Settings',
			'itemTracker.scan.useManual' => 'Type the code',
			'itemTracker.scan.nfcUnsupportedTitle' => 'This device has no NFC',
			'itemTracker.scan.nfcUnsupportedMessage' => 'You can identify the item with the camera or by typing the code.',
			'itemTracker.scan.nfcDisabledTitle' => 'NFC is turned off',
			'itemTracker.scan.nfcDisabledMessage' => 'Turn it on in the system Settings and check again.',
			'itemTracker.scan.checkAgain' => 'Check again',
			'itemTracker.scan.cameraError' => 'The camera could not be used. Type the code instead.',
			'itemTracker.scan.readError' => 'The identifier could not be read. Please try again.',
			'itemTracker.scan.readCancelled' => 'Reading cancelled.',
			'itemTracker.notFound.title' => 'Unregistered identifier',
			'itemTracker.notFound.message' => ({required Object type}) => 'This ${type} is not linked to any item.',
			'itemTracker.notFound.create' => 'Create new item',
			'itemTracker.notFound.associate' => 'Link to an existing item',
			'itemTracker.list.title' => 'Items',
			'itemTracker.list.search' => 'Search by name',
			'itemTracker.list.emptyTitle' => 'No items yet',
			'itemTracker.list.emptyMessage' => 'Scan a code to register the first one.',
			'itemTracker.list.noResults' => 'No items match the search.',
			'itemTracker.list.create' => 'Create item',
			'itemTracker.detail.title' => 'Item details',
			'itemTracker.detail.missingTitle' => 'Item not found',
			'itemTracker.detail.missingMessage' => 'It may have been removed.',
			'itemTracker.detail.edit' => 'Edit item',
			'itemTracker.detail.addEvent' => 'Add note',
			'itemTracker.detail.metadata' => 'Additional data',
			'itemTracker.detail.identifiers' => 'Identifiers',
			'itemTracker.detail.noIdentifiers' => 'No linked identifiers.',
			'itemTracker.detail.history' => 'History',
			'itemTracker.detail.eventsCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'No events', one: '1 event recorded', other: '${n} events recorded', ), 
			'itemTracker.detail.yes' => 'Yes',
			'itemTracker.detail.no' => 'No',
			'itemTracker.events.created' => ({required Object name}) => 'Item created as “${name}”',
			'itemTracker.events.updated' => ({required Object fields}) => 'Edited: ${fields}',
			'itemTracker.events.identifierBound' => ({required Object type, required Object value}) => '${type} linked: ${value}',
			'itemTracker.events.fieldName' => 'name',
			'itemTracker.events.fieldDescription' => 'description',
			'itemTracker.events.fieldMetadata' => 'additional data',
			'itemTracker.form.createTitle' => 'New item',
			'itemTracker.form.editTitle' => 'Edit item',
			'itemTracker.form.name' => 'Name',
			'itemTracker.form.description' => 'Description',
			'itemTracker.form.metadata' => 'Additional data',
			'itemTracker.form.metadataHelp' => 'Lowercase keys with underscores, for example label_color.',
			'itemTracker.form.addField' => 'Add data',
			'itemTracker.form.removeField' => ({required Object key}) => 'Remove data ${key}',
			'itemTracker.form.key' => 'Key',
			'itemTracker.form.value' => 'Value',
			'itemTracker.form.valueType' => 'Type',
			'itemTracker.form.typeText' => 'Text',
			'itemTracker.form.typeNumber' => 'Number',
			'itemTracker.form.typeBoolean' => 'Yes / No',
			'itemTracker.form.initialIdentifier' => ({required Object type, required Object value}) => 'The ${type} will be linked: ${value}',
			'itemTracker.form.save' => 'Save',
			'itemTracker.associate.title' => 'Link to an item',
			'itemTracker.associate.identifier' => ({required Object type, required Object value}) => '${type}: ${value}',
			'itemTracker.associate.search' => 'Search item by name',
			'itemTracker.associate.empty' => 'No items match the search.',
			'itemTracker.associate.select' => ({required Object name}) => 'Link to ${name}',
			'itemTracker.associate.success' => ({required Object name}) => 'Identifier linked to ${name}.',
			'itemTracker.addEvent.title' => 'Add note',
			'itemTracker.addEvent.eventTitle' => 'Title',
			'itemTracker.addEvent.eventDescription' => 'Description',
			'itemTracker.addEvent.save' => 'Save note',
			'itemTracker.errors.itemNotFound' => 'The item no longer exists.',
			'itemTracker.errors.alreadyBoundOther' => 'This identifier is already linked to another item.',
			'itemTracker.errors.alreadyBoundSame' => 'This identifier is already linked to this item.',
			'itemTracker.errors.openBoundItem' => 'View item',
			'itemTracker.errors.required' => 'This field is required.',
			'itemTracker.errors.tooLong' => 'The text is too long.',
			'itemTracker.errors.identifierInvalid' => 'The code contains invalid characters.',
			'itemTracker.errors.metadataKeyInvalid' => ({required Object key}) => 'The key “${key}” is not valid.',
			'itemTracker.errors.metadataKeyDuplicated' => ({required Object key}) => 'The key “${key}” is repeated.',
			'itemTracker.errors.metadataValueInvalid' => ({required Object key}) => 'The value of “${key}” is not valid.',
			'itemTracker.errors.metadataTooMany' => 'There is too much additional data.',
			'itemTracker.errors.numberInvalid' => 'Enter a valid number.',
			'itemTracker.errors.unexpected' => 'An unexpected error occurred.',
			_ => null,
		};
	}
}
