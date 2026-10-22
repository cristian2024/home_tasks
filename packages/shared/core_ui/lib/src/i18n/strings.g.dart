/// Generated file. Do not edit.
///
/// Source: lib/src/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 18 (9 per locale)
///
/// Built on 2026-10-22 at 03:36 UTC

// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

import 'strings_en.g.dart' as l_en;
part 'strings_es.g.dart';

/// Supported locales.
///
/// Usage:
/// - LocaleSettings.setLocale(CoreUiLocale.es) // set locale
/// - Locale locale = CoreUiLocale.es.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == CoreUiLocale.es) // locale check
enum CoreUiLocale with BaseAppLocale<CoreUiLocale, CoreUiTranslations> {
	es(languageCode: 'es'),
	en(languageCode: 'en');

	const CoreUiLocale({
		required this.languageCode,
		this.scriptCode, // ignore: unused_element, unused_element_parameter
		this.countryCode, // ignore: unused_element, unused_element_parameter
	});

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;

	@override
	Future<CoreUiTranslations> build({
		Map<String, Node>? overrides,
		PluralResolver? cardinalResolver,
		PluralResolver? ordinalResolver,
	}) async {
		return buildSync(
			overrides: overrides,
			cardinalResolver: cardinalResolver,
			ordinalResolver: ordinalResolver,
		);
	}

	@override
	CoreUiTranslations buildSync({
		Map<String, Node>? overrides,
		PluralResolver? cardinalResolver,
		PluralResolver? ordinalResolver,
	}) {
		switch (this) {
			case CoreUiLocale.es:
				return CoreUiTranslationsEs(
					overrides: overrides,
					cardinalResolver: cardinalResolver,
					ordinalResolver: ordinalResolver,
				);
			case CoreUiLocale.en:
				return l_en.CoreUiTranslationsEn(
					overrides: overrides,
					cardinalResolver: cardinalResolver,
					ordinalResolver: ordinalResolver,
				);
		}
	}

	/// Gets current instance managed by [LocaleSettings].
	CoreUiTranslations get translations => LocaleSettings.instance.getTranslations(this);
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of commonStrings).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = commonStrings.someKey.anotherKey;
/// String b = commonStrings['someKey.anotherKey']; // Only for edge cases!
CoreUiTranslations get commonStrings => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final commonStrings = CoreUiTranslations.of(context); // Get commonStrings variable.
/// String a = commonStrings.someKey.anotherKey; // Use commonStrings variable.
/// String b = commonStrings['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<CoreUiLocale, CoreUiTranslations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<CoreUiLocale, CoreUiTranslations> of(BuildContext context) => InheritedLocaleData.of<CoreUiLocale, CoreUiTranslations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.commonStrings.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	CoreUiTranslations get commonStrings => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<CoreUiLocale, CoreUiTranslations> {
	LocaleSettings._() : super(
		utils: AppLocaleUtils.instance,
		lazy: false,
	);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static CoreUiLocale get currentLocale => instance.currentLocale;
	static Stream<CoreUiLocale> getLocaleStream() => instance.getLocaleStream();
	static Future<CoreUiLocale> setLocale(CoreUiLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static Future<CoreUiLocale> setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static Future<CoreUiLocale> useDeviceLocale() => instance.useDeviceLocale();
	static Future<void> setPluralResolver({String? language, CoreUiLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);

	// synchronous versions
	static CoreUiLocale setLocaleSync(CoreUiLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocaleSync(locale, listenToDeviceLocale: listenToDeviceLocale);
	static CoreUiLocale setLocaleRawSync(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRawSync(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static CoreUiLocale useDeviceLocaleSync() => instance.useDeviceLocaleSync();
	static void setPluralResolverSync({String? language, CoreUiLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolverSync(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<CoreUiLocale, CoreUiTranslations> {
	AppLocaleUtils._() : super(
		baseLocale: CoreUiLocale.es,
		locales: CoreUiLocale.values,
	);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static CoreUiLocale parse(String rawLocale) => instance.parse(rawLocale);
	static CoreUiLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static CoreUiLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}
