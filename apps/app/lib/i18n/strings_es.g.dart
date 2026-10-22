///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef AppTranslationsEs = AppTranslations; // ignore: unused_element
class AppTranslations with BaseTranslations<AppLocale, AppTranslations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final appStrings = AppTranslations.of(context);
	static AppTranslations of(BuildContext context) => InheritedLocaleData.of<AppLocale, AppTranslations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	AppTranslations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, AppTranslations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	final TranslationMetadata<AppLocale, AppTranslations> _meta;
	@override TranslationMetadata<AppLocale, AppTranslations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final AppTranslations _root = this; // ignore: unused_field

	AppTranslations $copyWith({TranslationMetadata<AppLocale, AppTranslations>? meta}) => AppTranslations(meta: meta ?? this.$meta);

	// Translations
	late final AppTranslations$app$es app = AppTranslations$app$es._(_root);
}

// Path: app
class AppTranslations$app$es {
	AppTranslations$app$es._(this._root);

	final AppTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Utilidades del Hogar'
	String get title => 'Utilidades del Hogar';

	late final AppTranslations$app$home$es home = AppTranslations$app$home$es._(_root);
	late final AppTranslations$app$catalog$es catalog = AppTranslations$app$catalog$es._(_root);
	late final AppTranslations$app$guard$es guard = AppTranslations$app$guard$es._(_root);
}

// Path: app.home
class AppTranslations$app$home$es {
	AppTranslations$app$home$es._(this._root);

	final AppTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Inicio'
	String get title => 'Inicio';

	/// es: 'Módulos'
	String get openCatalog => 'Módulos';

	/// es: 'No hay módulos activos'
	String get emptyTitle => 'No hay módulos activos';

	/// es: 'Activa algún módulo en el catálogo para verlo aquí.'
	String get emptyMessage => 'Activa algún módulo en el catálogo para verlo aquí.';

	/// es: 'Mantén pulsada una tarjeta para cambiar el orden.'
	String get reorderHint => 'Mantén pulsada una tarjeta para cambiar el orden.';

	/// es: 'No se pudo iniciar «{name}».'
	String pluginFailed({required Object name}) => 'No se pudo iniciar «${name}».';

	/// es: 'Reintentar'
	String get retry => 'Reintentar';
}

// Path: app.catalog
class AppTranslations$app$catalog$es {
	AppTranslations$app$catalog$es._(this._root);

	final AppTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Módulos'
	String get title => 'Módulos';

	/// es: 'Activa o desactiva los módulos. Al desactivar uno, sus datos se conservan.'
	String get description => 'Activa o desactiva los módulos. Al desactivar uno, sus datos se conservan.';

	/// es: 'No disponible en este dispositivo.'
	String get unavailable => 'No disponible en este dispositivo.';

	/// es: 'Activo, pero no se pudo iniciar.'
	String get failed => 'Activo, pero no se pudo iniciar.';

	/// es: 'Activo'
	String get enabled => 'Activo';

	/// es: 'Desactivado'
	String get disabled => 'Desactivado';
}

// Path: app.guard
class AppTranslations$app$guard$es {
	AppTranslations$app$guard$es._(this._root);

	final AppTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Ese módulo está desactivado. Actívalo en el catálogo para usarlo.'
	String get pluginDisabled => 'Ese módulo está desactivado. Actívalo en el catálogo para usarlo.';

	/// es: 'Ese módulo no está disponible en este momento.'
	String get pluginUnavailable => 'Ese módulo no está disponible en este momento.';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppTranslations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Utilidades del Hogar',
			'app.home.title' => 'Inicio',
			'app.home.openCatalog' => 'Módulos',
			'app.home.emptyTitle' => 'No hay módulos activos',
			'app.home.emptyMessage' => 'Activa algún módulo en el catálogo para verlo aquí.',
			'app.home.reorderHint' => 'Mantén pulsada una tarjeta para cambiar el orden.',
			'app.home.pluginFailed' => ({required Object name}) => 'No se pudo iniciar «${name}».',
			'app.home.retry' => 'Reintentar',
			'app.catalog.title' => 'Módulos',
			'app.catalog.description' => 'Activa o desactiva los módulos. Al desactivar uno, sus datos se conservan.',
			'app.catalog.unavailable' => 'No disponible en este dispositivo.',
			'app.catalog.failed' => 'Activo, pero no se pudo iniciar.',
			'app.catalog.enabled' => 'Activo',
			'app.catalog.disabled' => 'Desactivado',
			'app.guard.pluginDisabled' => 'Ese módulo está desactivado. Actívalo en el catálogo para usarlo.',
			'app.guard.pluginUnavailable' => 'Ese módulo no está disponible en este momento.',
			_ => null,
		};
	}
}
