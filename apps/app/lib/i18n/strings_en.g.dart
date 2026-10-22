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
class AppTranslationsEn with BaseTranslations<AppLocale, AppTranslations> implements AppTranslations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	AppTranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, AppTranslations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, AppTranslations> _meta;
	@override TranslationMetadata<AppLocale, AppTranslations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key);

	late final AppTranslationsEn _root = this; // ignore: unused_field

	@override 
	AppTranslationsEn $copyWith({TranslationMetadata<AppLocale, AppTranslations>? meta}) => AppTranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _AppTranslations$app$en app = _AppTranslations$app$en._(_root);
}

// Path: app
class _AppTranslations$app$en implements AppTranslations$app$es {
	_AppTranslations$app$en._(this._root);

	final AppTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home Utilities';
	@override late final _AppTranslations$app$home$en home = _AppTranslations$app$home$en._(_root);
	@override late final _AppTranslations$app$catalog$en catalog = _AppTranslations$app$catalog$en._(_root);
	@override late final _AppTranslations$app$guard$en guard = _AppTranslations$app$guard$en._(_root);
}

// Path: app.home
class _AppTranslations$app$home$en implements AppTranslations$app$home$es {
	_AppTranslations$app$home$en._(this._root);

	final AppTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home';
	@override String get openCatalog => 'Modules';
	@override String get emptyTitle => 'No active modules';
	@override String get emptyMessage => 'Turn on a module in the catalog to see it here.';
	@override String get reorderHint => 'Long-press a card to change the order.';
	@override String pluginFailed({required Object name}) => '“${name}” could not be started.';
	@override String get retry => 'Retry';
}

// Path: app.catalog
class _AppTranslations$app$catalog$en implements AppTranslations$app$catalog$es {
	_AppTranslations$app$catalog$en._(this._root);

	final AppTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Modules';
	@override String get description => 'Turn modules on or off. Turning one off keeps its data.';
	@override String get unavailable => 'Not available on this device.';
	@override String get failed => 'On, but it could not be started.';
	@override String get enabled => 'On';
	@override String get disabled => 'Off';
}

// Path: app.guard
class _AppTranslations$app$guard$en implements AppTranslations$app$guard$es {
	_AppTranslations$app$guard$en._(this._root);

	final AppTranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pluginDisabled => 'That module is turned off. Turn it on in the catalog to use it.';
	@override String get pluginUnavailable => 'That module is not available right now.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppTranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Home Utilities',
			'app.home.title' => 'Home',
			'app.home.openCatalog' => 'Modules',
			'app.home.emptyTitle' => 'No active modules',
			'app.home.emptyMessage' => 'Turn on a module in the catalog to see it here.',
			'app.home.reorderHint' => 'Long-press a card to change the order.',
			'app.home.pluginFailed' => ({required Object name}) => '“${name}” could not be started.',
			'app.home.retry' => 'Retry',
			'app.catalog.title' => 'Modules',
			'app.catalog.description' => 'Turn modules on or off. Turning one off keeps its data.',
			'app.catalog.unavailable' => 'Not available on this device.',
			'app.catalog.failed' => 'On, but it could not be started.',
			'app.catalog.enabled' => 'On',
			'app.catalog.disabled' => 'Off',
			'app.guard.pluginDisabled' => 'That module is turned off. Turn it on in the catalog to use it.',
			'app.guard.pluginUnavailable' => 'That module is not available right now.',
			_ => null,
		};
	}
}
