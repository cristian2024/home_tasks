///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef ItemTrackerTranslationsEs = ItemTrackerTranslations; // ignore: unused_element
class ItemTrackerTranslations with BaseTranslations<ItemTrackerLocale, ItemTrackerTranslations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final itemTrackerStrings = ItemTrackerTranslations.of(context);
	static ItemTrackerTranslations of(BuildContext context) => InheritedLocaleData.of<ItemTrackerLocale, ItemTrackerTranslations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [ItemTrackerLocale.build] is preferred.
	ItemTrackerTranslations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<ItemTrackerLocale, ItemTrackerTranslations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: ItemTrackerLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	final TranslationMetadata<ItemTrackerLocale, ItemTrackerTranslations> _meta;
	@override TranslationMetadata<ItemTrackerLocale, ItemTrackerTranslations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final ItemTrackerTranslations _root = this; // ignore: unused_field

	ItemTrackerTranslations $copyWith({TranslationMetadata<ItemTrackerLocale, ItemTrackerTranslations>? meta}) => ItemTrackerTranslations(meta: meta ?? this.$meta);

	// Translations
	late final ItemTrackerTranslations$itemTracker$es itemTracker = ItemTrackerTranslations$itemTracker$es._(_root);
}

// Path: itemTracker
class ItemTrackerTranslations$itemTracker$es {
	ItemTrackerTranslations$itemTracker$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Seguimiento de Objetos'
	String get title => 'Seguimiento de Objetos';

	/// es: 'Identifica tus objetos con códigos QR, de barras o etiquetas NFC.'
	String get description => 'Identifica tus objetos con códigos QR, de barras o etiquetas NFC.';

	late final ItemTrackerTranslations$itemTracker$dashboard$es dashboard = ItemTrackerTranslations$itemTracker$dashboard$es._(_root);
	late final ItemTrackerTranslations$itemTracker$identifierTypes$es identifierTypes = ItemTrackerTranslations$itemTracker$identifierTypes$es._(_root);
	late final ItemTrackerTranslations$itemTracker$scan$es scan = ItemTrackerTranslations$itemTracker$scan$es._(_root);
	late final ItemTrackerTranslations$itemTracker$notFound$es notFound = ItemTrackerTranslations$itemTracker$notFound$es._(_root);
	late final ItemTrackerTranslations$itemTracker$list$es list = ItemTrackerTranslations$itemTracker$list$es._(_root);
	late final ItemTrackerTranslations$itemTracker$detail$es detail = ItemTrackerTranslations$itemTracker$detail$es._(_root);
	late final ItemTrackerTranslations$itemTracker$events$es events = ItemTrackerTranslations$itemTracker$events$es._(_root);
	late final ItemTrackerTranslations$itemTracker$form$es form = ItemTrackerTranslations$itemTracker$form$es._(_root);
	late final ItemTrackerTranslations$itemTracker$associate$es associate = ItemTrackerTranslations$itemTracker$associate$es._(_root);
	late final ItemTrackerTranslations$itemTracker$addEvent$es addEvent = ItemTrackerTranslations$itemTracker$addEvent$es._(_root);
	late final ItemTrackerTranslations$itemTracker$errors$es errors = ItemTrackerTranslations$itemTracker$errors$es._(_root);
}

// Path: itemTracker.dashboard
class ItemTrackerTranslations$itemTracker$dashboard$es {
	ItemTrackerTranslations$itemTracker$dashboard$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Escanear'
	String get scan => 'Escanear';

	/// es: 'Ver objetos'
	String get items => 'Ver objetos';

	/// es: '(zero) {Aún no hay objetos registrados} (one) {1 objeto registrado} (other) {{n} objetos registrados}'
	String itemsCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		zero: 'Aún no hay objetos registrados',
		one: '1 objeto registrado',
		other: '${n} objetos registrados',
	);
}

// Path: itemTracker.identifierTypes
class ItemTrackerTranslations$itemTracker$identifierTypes$es {
	ItemTrackerTranslations$itemTracker$identifierTypes$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'QR'
	String get qr => 'QR';

	/// es: 'Código de barras'
	String get barcode => 'Código de barras';

	/// es: 'NFC'
	String get nfc => 'NFC';
}

// Path: itemTracker.scan
class ItemTrackerTranslations$itemTracker$scan$es {
	ItemTrackerTranslations$itemTracker$scan$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Escanear'
	String get title => 'Escanear';

	/// es: 'Modo de identificación'
	String get modeLabel => 'Modo de identificación';

	/// es: 'Cámara'
	String get modeCamera => 'Cámara';

	/// es: 'NFC'
	String get modeNfc => 'NFC';

	/// es: 'Código'
	String get modeManual => 'Código';

	/// es: 'Apunta al código QR o de barras.'
	String get promptCamera => 'Apunta al código QR o de barras.';

	/// es: 'Pulsa «Leer etiqueta» y acerca la etiqueta NFC.'
	String get promptNfc => 'Pulsa «Leer etiqueta» y acerca la etiqueta NFC.';

	/// es: 'Leer etiqueta'
	String get nfcStart => 'Leer etiqueta';

	/// es: 'Cancelar lectura'
	String get nfcCancel => 'Cancelar lectura';

	/// es: 'Acerca la etiqueta NFC al teléfono…'
	String get nfcWaiting => 'Acerca la etiqueta NFC al teléfono…';

	/// es: 'Código'
	String get manualLabel => 'Código';

	/// es: 'Escribe el código tal como aparece'
	String get manualHint => 'Escribe el código tal como aparece';

	/// es: 'Tipo de identificador'
	String get typeLabel => 'Tipo de identificador';

	/// es: 'Buscar'
	String get manualSubmit => 'Buscar';

	/// es: 'Buscando el objeto…'
	String get lookingUp => 'Buscando el objeto…';

	/// es: '{type} leído: {value}'
	String readAnnouncement({required Object type, required Object value}) => '${type} leído: ${value}';

	/// es: 'Se necesita la cámara'
	String get cameraPermissionTitle => 'Se necesita la cámara';

	/// es: 'Concede el permiso de cámara para escanear códigos, o escribe el código a mano.'
	String get cameraPermissionMessage => 'Concede el permiso de cámara para escanear códigos, o escribe el código a mano.';

	/// es: 'El permiso de cámara está denegado. Actívalo en los Ajustes de la app o escribe el código a mano.'
	String get cameraPermanentlyDeniedMessage => 'El permiso de cámara está denegado. Actívalo en los Ajustes de la app o escribe el código a mano.';

	/// es: 'El sistema no permite usar la cámara en este dispositivo. Escribe el código a mano.'
	String get cameraRestrictedMessage => 'El sistema no permite usar la cámara en este dispositivo. Escribe el código a mano.';

	/// es: 'Conceder permiso'
	String get grantPermission => 'Conceder permiso';

	/// es: 'Abrir Ajustes'
	String get openSettings => 'Abrir Ajustes';

	/// es: 'Escribir el código'
	String get useManual => 'Escribir el código';

	/// es: 'Este dispositivo no tiene NFC'
	String get nfcUnsupportedTitle => 'Este dispositivo no tiene NFC';

	/// es: 'Puedes identificar el objeto con la cámara o escribiendo el código.'
	String get nfcUnsupportedMessage => 'Puedes identificar el objeto con la cámara o escribiendo el código.';

	/// es: 'NFC está desactivado'
	String get nfcDisabledTitle => 'NFC está desactivado';

	/// es: 'Actívalo en los Ajustes del sistema y vuelve a comprobarlo.'
	String get nfcDisabledMessage => 'Actívalo en los Ajustes del sistema y vuelve a comprobarlo.';

	/// es: 'Comprobar de nuevo'
	String get checkAgain => 'Comprobar de nuevo';

	/// es: 'No se pudo usar la cámara. Escribe el código a mano.'
	String get cameraError => 'No se pudo usar la cámara. Escribe el código a mano.';

	/// es: 'No se pudo leer el identificador. Inténtalo de nuevo.'
	String get readError => 'No se pudo leer el identificador. Inténtalo de nuevo.';

	/// es: 'Lectura cancelada.'
	String get readCancelled => 'Lectura cancelada.';

	/// es: 'Añadir identificador'
	String get bindTitle => 'Añadir identificador';

	/// es: 'Asociando el identificador…'
	String get binding => 'Asociando el identificador…';

	/// es: 'Asociar'
	String get bindSubmit => 'Asociar';

	/// es: 'Identificador añadido.'
	String get bound => 'Identificador añadido.';

	/// es: 'Este identificador ya está asociado a «{name}».'
	String bindRejectedOther({required Object name}) => 'Este identificador ya está asociado a «${name}».';
}

// Path: itemTracker.notFound
class ItemTrackerTranslations$itemTracker$notFound$es {
	ItemTrackerTranslations$itemTracker$notFound$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Identificador no registrado'
	String get title => 'Identificador no registrado';

	/// es: 'Este {type} no está asociado a ningún objeto.'
	String message({required Object type}) => 'Este ${type} no está asociado a ningún objeto.';

	/// es: 'Crear nuevo objeto'
	String get create => 'Crear nuevo objeto';

	/// es: 'Asociar a un objeto existente'
	String get associate => 'Asociar a un objeto existente';
}

// Path: itemTracker.list
class ItemTrackerTranslations$itemTracker$list$es {
	ItemTrackerTranslations$itemTracker$list$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Objetos'
	String get title => 'Objetos';

	/// es: 'Buscar por nombre'
	String get search => 'Buscar por nombre';

	/// es: 'Aún no hay objetos'
	String get emptyTitle => 'Aún no hay objetos';

	/// es: 'Escanea un código para registrar el primero.'
	String get emptyMessage => 'Escanea un código para registrar el primero.';

	/// es: 'Ningún objeto coincide con la búsqueda.'
	String get noResults => 'Ningún objeto coincide con la búsqueda.';

	/// es: 'Crear objeto'
	String get create => 'Crear objeto';
}

// Path: itemTracker.detail
class ItemTrackerTranslations$itemTracker$detail$es {
	ItemTrackerTranslations$itemTracker$detail$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Detalle del objeto'
	String get title => 'Detalle del objeto';

	/// es: 'Objeto no encontrado'
	String get missingTitle => 'Objeto no encontrado';

	/// es: 'Puede que se haya eliminado.'
	String get missingMessage => 'Puede que se haya eliminado.';

	/// es: 'Editar objeto'
	String get edit => 'Editar objeto';

	/// es: 'Añadir nota'
	String get addEvent => 'Añadir nota';

	/// es: 'Datos adicionales'
	String get metadata => 'Datos adicionales';

	/// es: 'Identificadores'
	String get identifiers => 'Identificadores';

	/// es: 'Sin identificadores asociados.'
	String get noIdentifiers => 'Sin identificadores asociados.';

	/// es: 'Historial'
	String get history => 'Historial';

	/// es: '(zero) {Sin eventos} (one) {1 evento registrado} (other) {{n} eventos registrados}'
	String eventsCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		zero: 'Sin eventos',
		one: '1 evento registrado',
		other: '${n} eventos registrados',
	);

	/// es: 'Sí'
	String get yes => 'Sí';

	/// es: 'No'
	String get no => 'No';

	/// es: 'Añadir identificador'
	String get addIdentifier => 'Añadir identificador';

	/// es: 'Quitar {type} {value}'
	String removeIdentifier({required Object type, required Object value}) => 'Quitar ${type} ${value}';

	/// es: '¿Quitar el identificador?'
	String get removeIdentifierTitle => '¿Quitar el identificador?';

	/// es: 'El {type} «{value}» dejará de abrir este objeto. Podrás volver a asociarlo a cualquier objeto.'
	String removeIdentifierMessage({required Object type, required Object value}) => 'El ${type} «${value}» dejará de abrir este objeto. Podrás volver a asociarlo a cualquier objeto.';

	/// es: 'Quitar'
	String get removeIdentifierConfirm => 'Quitar';

	/// es: 'Identificador quitado.'
	String get identifierRemoved => 'Identificador quitado.';
}

// Path: itemTracker.events
class ItemTrackerTranslations$itemTracker$events$es {
	ItemTrackerTranslations$itemTracker$events$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Objeto creado como «{name}»'
	String created({required Object name}) => 'Objeto creado como «${name}»';

	/// es: 'Se editó: {fields}'
	String updated({required Object fields}) => 'Se editó: ${fields}';

	/// es: '{type} asociado: {value}'
	String identifierBound({required Object type, required Object value}) => '${type} asociado: ${value}';

	/// es: 'nombre'
	String get fieldName => 'nombre';

	/// es: 'descripción'
	String get fieldDescription => 'descripción';

	/// es: 'datos adicionales'
	String get fieldMetadata => 'datos adicionales';

	/// es: '{type} quitado: {value}'
	String identifierUnbound({required Object type, required Object value}) => '${type} quitado: ${value}';

	/// es: 'Movido a «{name}»'
	String moved({required Object name}) => 'Movido a «${name}»';

	/// es: 'Sacado de su contenedor'
	String get movedOut => 'Sacado de su contenedor';

	/// es: 'Entró «{name}»'
	String childAdded({required Object name}) => 'Entró «${name}»';

	/// es: 'Salió «{name}»'
	String childRemoved({required Object name}) => 'Salió «${name}»';
}

// Path: itemTracker.form
class ItemTrackerTranslations$itemTracker$form$es {
	ItemTrackerTranslations$itemTracker$form$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Nuevo objeto'
	String get createTitle => 'Nuevo objeto';

	/// es: 'Editar objeto'
	String get editTitle => 'Editar objeto';

	/// es: 'Nombre'
	String get name => 'Nombre';

	/// es: 'Descripción'
	String get description => 'Descripción';

	/// es: 'Datos adicionales'
	String get metadata => 'Datos adicionales';

	/// es: 'Claves en minúsculas con guiones bajos, por ejemplo color_etiqueta.'
	String get metadataHelp => 'Claves en minúsculas con guiones bajos, por ejemplo color_etiqueta.';

	/// es: 'Añadir dato'
	String get addField => 'Añadir dato';

	/// es: 'Quitar dato {key}'
	String removeField({required Object key}) => 'Quitar dato ${key}';

	/// es: 'Clave'
	String get key => 'Clave';

	/// es: 'Valor'
	String get value => 'Valor';

	/// es: 'Tipo'
	String get valueType => 'Tipo';

	/// es: 'Texto'
	String get typeText => 'Texto';

	/// es: 'Número'
	String get typeNumber => 'Número';

	/// es: 'Sí / No'
	String get typeBoolean => 'Sí / No';

	/// es: 'Se asociará el {type}: {value}'
	String initialIdentifier({required Object type, required Object value}) => 'Se asociará el ${type}: ${value}';

	/// es: 'Guardar'
	String get save => 'Guardar';

	/// es: 'Identificadores'
	String get identifiers => 'Identificadores';

	/// es: 'Se asocian al momento, sin necesidad de guardar.'
	String get identifiersHelp => 'Se asocian al momento, sin necesidad de guardar.';

	/// es: 'Añadir identificador'
	String get addIdentifier => 'Añadir identificador';
}

// Path: itemTracker.associate
class ItemTrackerTranslations$itemTracker$associate$es {
	ItemTrackerTranslations$itemTracker$associate$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Asociar a un objeto'
	String get title => 'Asociar a un objeto';

	/// es: '{type}: {value}'
	String identifier({required Object type, required Object value}) => '${type}: ${value}';

	/// es: 'Buscar objeto por nombre'
	String get search => 'Buscar objeto por nombre';

	/// es: 'Ningún objeto coincide con la búsqueda.'
	String get empty => 'Ningún objeto coincide con la búsqueda.';

	/// es: 'Asociar a {name}'
	String select({required Object name}) => 'Asociar a ${name}';

	/// es: 'Identificador asociado a {name}.'
	String success({required Object name}) => 'Identificador asociado a ${name}.';
}

// Path: itemTracker.addEvent
class ItemTrackerTranslations$itemTracker$addEvent$es {
	ItemTrackerTranslations$itemTracker$addEvent$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'Añadir nota'
	String get title => 'Añadir nota';

	/// es: 'Título'
	String get eventTitle => 'Título';

	/// es: 'Descripción'
	String get eventDescription => 'Descripción';

	/// es: 'Guardar nota'
	String get save => 'Guardar nota';
}

// Path: itemTracker.errors
class ItemTrackerTranslations$itemTracker$errors$es {
	ItemTrackerTranslations$itemTracker$errors$es._(this._root);

	final ItemTrackerTranslations _root; // ignore: unused_field

	// Translations

	/// es: 'El objeto ya no existe.'
	String get itemNotFound => 'El objeto ya no existe.';

	/// es: 'Este identificador ya está asociado a otro objeto.'
	String get alreadyBoundOther => 'Este identificador ya está asociado a otro objeto.';

	/// es: 'Este identificador ya está asociado a este objeto.'
	String get alreadyBoundSame => 'Este identificador ya está asociado a este objeto.';

	/// es: 'Ver objeto'
	String get openBoundItem => 'Ver objeto';

	/// es: 'Este campo es obligatorio.'
	String get required => 'Este campo es obligatorio.';

	/// es: 'El texto es demasiado largo.'
	String get tooLong => 'El texto es demasiado largo.';

	/// es: 'El código contiene caracteres no válidos.'
	String get identifierInvalid => 'El código contiene caracteres no válidos.';

	/// es: 'La clave «{key}» no es válida.'
	String metadataKeyInvalid({required Object key}) => 'La clave «${key}» no es válida.';

	/// es: 'La clave «{key}» está repetida.'
	String metadataKeyDuplicated({required Object key}) => 'La clave «${key}» está repetida.';

	/// es: 'El valor de «{key}» no es válido.'
	String metadataValueInvalid({required Object key}) => 'El valor de «${key}» no es válido.';

	/// es: 'Hay demasiados datos adicionales.'
	String get metadataTooMany => 'Hay demasiados datos adicionales.';

	/// es: 'Escribe un número válido.'
	String get numberInvalid => 'Escribe un número válido.';

	/// es: 'Ocurrió un error inesperado.'
	String get unexpected => 'Ocurrió un error inesperado.';

	/// es: 'El identificador ya no está asociado a este objeto.'
	String get identifierNotFound => 'El identificador ya no está asociado a este objeto.';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on ItemTrackerTranslations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'itemTracker.title' => 'Seguimiento de Objetos',
			'itemTracker.description' => 'Identifica tus objetos con códigos QR, de barras o etiquetas NFC.',
			'itemTracker.dashboard.scan' => 'Escanear',
			'itemTracker.dashboard.items' => 'Ver objetos',
			'itemTracker.dashboard.itemsCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, zero: 'Aún no hay objetos registrados', one: '1 objeto registrado', other: '${n} objetos registrados', ), 
			'itemTracker.identifierTypes.qr' => 'QR',
			'itemTracker.identifierTypes.barcode' => 'Código de barras',
			'itemTracker.identifierTypes.nfc' => 'NFC',
			'itemTracker.scan.title' => 'Escanear',
			'itemTracker.scan.modeLabel' => 'Modo de identificación',
			'itemTracker.scan.modeCamera' => 'Cámara',
			'itemTracker.scan.modeNfc' => 'NFC',
			'itemTracker.scan.modeManual' => 'Código',
			'itemTracker.scan.promptCamera' => 'Apunta al código QR o de barras.',
			'itemTracker.scan.promptNfc' => 'Pulsa «Leer etiqueta» y acerca la etiqueta NFC.',
			'itemTracker.scan.nfcStart' => 'Leer etiqueta',
			'itemTracker.scan.nfcCancel' => 'Cancelar lectura',
			'itemTracker.scan.nfcWaiting' => 'Acerca la etiqueta NFC al teléfono…',
			'itemTracker.scan.manualLabel' => 'Código',
			'itemTracker.scan.manualHint' => 'Escribe el código tal como aparece',
			'itemTracker.scan.typeLabel' => 'Tipo de identificador',
			'itemTracker.scan.manualSubmit' => 'Buscar',
			'itemTracker.scan.lookingUp' => 'Buscando el objeto…',
			'itemTracker.scan.readAnnouncement' => ({required Object type, required Object value}) => '${type} leído: ${value}',
			'itemTracker.scan.cameraPermissionTitle' => 'Se necesita la cámara',
			'itemTracker.scan.cameraPermissionMessage' => 'Concede el permiso de cámara para escanear códigos, o escribe el código a mano.',
			'itemTracker.scan.cameraPermanentlyDeniedMessage' => 'El permiso de cámara está denegado. Actívalo en los Ajustes de la app o escribe el código a mano.',
			'itemTracker.scan.cameraRestrictedMessage' => 'El sistema no permite usar la cámara en este dispositivo. Escribe el código a mano.',
			'itemTracker.scan.grantPermission' => 'Conceder permiso',
			'itemTracker.scan.openSettings' => 'Abrir Ajustes',
			'itemTracker.scan.useManual' => 'Escribir el código',
			'itemTracker.scan.nfcUnsupportedTitle' => 'Este dispositivo no tiene NFC',
			'itemTracker.scan.nfcUnsupportedMessage' => 'Puedes identificar el objeto con la cámara o escribiendo el código.',
			'itemTracker.scan.nfcDisabledTitle' => 'NFC está desactivado',
			'itemTracker.scan.nfcDisabledMessage' => 'Actívalo en los Ajustes del sistema y vuelve a comprobarlo.',
			'itemTracker.scan.checkAgain' => 'Comprobar de nuevo',
			'itemTracker.scan.cameraError' => 'No se pudo usar la cámara. Escribe el código a mano.',
			'itemTracker.scan.readError' => 'No se pudo leer el identificador. Inténtalo de nuevo.',
			'itemTracker.scan.readCancelled' => 'Lectura cancelada.',
			'itemTracker.scan.bindTitle' => 'Añadir identificador',
			'itemTracker.scan.binding' => 'Asociando el identificador…',
			'itemTracker.scan.bindSubmit' => 'Asociar',
			'itemTracker.scan.bound' => 'Identificador añadido.',
			'itemTracker.scan.bindRejectedOther' => ({required Object name}) => 'Este identificador ya está asociado a «${name}».',
			'itemTracker.notFound.title' => 'Identificador no registrado',
			'itemTracker.notFound.message' => ({required Object type}) => 'Este ${type} no está asociado a ningún objeto.',
			'itemTracker.notFound.create' => 'Crear nuevo objeto',
			'itemTracker.notFound.associate' => 'Asociar a un objeto existente',
			'itemTracker.list.title' => 'Objetos',
			'itemTracker.list.search' => 'Buscar por nombre',
			'itemTracker.list.emptyTitle' => 'Aún no hay objetos',
			'itemTracker.list.emptyMessage' => 'Escanea un código para registrar el primero.',
			'itemTracker.list.noResults' => 'Ningún objeto coincide con la búsqueda.',
			'itemTracker.list.create' => 'Crear objeto',
			'itemTracker.detail.title' => 'Detalle del objeto',
			'itemTracker.detail.missingTitle' => 'Objeto no encontrado',
			'itemTracker.detail.missingMessage' => 'Puede que se haya eliminado.',
			'itemTracker.detail.edit' => 'Editar objeto',
			'itemTracker.detail.addEvent' => 'Añadir nota',
			'itemTracker.detail.metadata' => 'Datos adicionales',
			'itemTracker.detail.identifiers' => 'Identificadores',
			'itemTracker.detail.noIdentifiers' => 'Sin identificadores asociados.',
			'itemTracker.detail.history' => 'Historial',
			'itemTracker.detail.eventsCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, zero: 'Sin eventos', one: '1 evento registrado', other: '${n} eventos registrados', ), 
			'itemTracker.detail.yes' => 'Sí',
			'itemTracker.detail.no' => 'No',
			'itemTracker.detail.addIdentifier' => 'Añadir identificador',
			'itemTracker.detail.removeIdentifier' => ({required Object type, required Object value}) => 'Quitar ${type} ${value}',
			'itemTracker.detail.removeIdentifierTitle' => '¿Quitar el identificador?',
			'itemTracker.detail.removeIdentifierMessage' => ({required Object type, required Object value}) => 'El ${type} «${value}» dejará de abrir este objeto. Podrás volver a asociarlo a cualquier objeto.',
			'itemTracker.detail.removeIdentifierConfirm' => 'Quitar',
			'itemTracker.detail.identifierRemoved' => 'Identificador quitado.',
			'itemTracker.events.created' => ({required Object name}) => 'Objeto creado como «${name}»',
			'itemTracker.events.updated' => ({required Object fields}) => 'Se editó: ${fields}',
			'itemTracker.events.identifierBound' => ({required Object type, required Object value}) => '${type} asociado: ${value}',
			'itemTracker.events.fieldName' => 'nombre',
			'itemTracker.events.fieldDescription' => 'descripción',
			'itemTracker.events.fieldMetadata' => 'datos adicionales',
			'itemTracker.events.identifierUnbound' => ({required Object type, required Object value}) => '${type} quitado: ${value}',
			'itemTracker.events.moved' => ({required Object name}) => 'Movido a «${name}»',
			'itemTracker.events.movedOut' => 'Sacado de su contenedor',
			'itemTracker.events.childAdded' => ({required Object name}) => 'Entró «${name}»',
			'itemTracker.events.childRemoved' => ({required Object name}) => 'Salió «${name}»',
			'itemTracker.form.createTitle' => 'Nuevo objeto',
			'itemTracker.form.editTitle' => 'Editar objeto',
			'itemTracker.form.name' => 'Nombre',
			'itemTracker.form.description' => 'Descripción',
			'itemTracker.form.metadata' => 'Datos adicionales',
			'itemTracker.form.metadataHelp' => 'Claves en minúsculas con guiones bajos, por ejemplo color_etiqueta.',
			'itemTracker.form.addField' => 'Añadir dato',
			'itemTracker.form.removeField' => ({required Object key}) => 'Quitar dato ${key}',
			'itemTracker.form.key' => 'Clave',
			'itemTracker.form.value' => 'Valor',
			'itemTracker.form.valueType' => 'Tipo',
			'itemTracker.form.typeText' => 'Texto',
			'itemTracker.form.typeNumber' => 'Número',
			'itemTracker.form.typeBoolean' => 'Sí / No',
			'itemTracker.form.initialIdentifier' => ({required Object type, required Object value}) => 'Se asociará el ${type}: ${value}',
			'itemTracker.form.save' => 'Guardar',
			'itemTracker.form.identifiers' => 'Identificadores',
			'itemTracker.form.identifiersHelp' => 'Se asocian al momento, sin necesidad de guardar.',
			'itemTracker.form.addIdentifier' => 'Añadir identificador',
			'itemTracker.associate.title' => 'Asociar a un objeto',
			'itemTracker.associate.identifier' => ({required Object type, required Object value}) => '${type}: ${value}',
			'itemTracker.associate.search' => 'Buscar objeto por nombre',
			'itemTracker.associate.empty' => 'Ningún objeto coincide con la búsqueda.',
			'itemTracker.associate.select' => ({required Object name}) => 'Asociar a ${name}',
			'itemTracker.associate.success' => ({required Object name}) => 'Identificador asociado a ${name}.',
			'itemTracker.addEvent.title' => 'Añadir nota',
			'itemTracker.addEvent.eventTitle' => 'Título',
			'itemTracker.addEvent.eventDescription' => 'Descripción',
			'itemTracker.addEvent.save' => 'Guardar nota',
			'itemTracker.errors.itemNotFound' => 'El objeto ya no existe.',
			'itemTracker.errors.alreadyBoundOther' => 'Este identificador ya está asociado a otro objeto.',
			'itemTracker.errors.alreadyBoundSame' => 'Este identificador ya está asociado a este objeto.',
			'itemTracker.errors.openBoundItem' => 'Ver objeto',
			'itemTracker.errors.required' => 'Este campo es obligatorio.',
			'itemTracker.errors.tooLong' => 'El texto es demasiado largo.',
			'itemTracker.errors.identifierInvalid' => 'El código contiene caracteres no válidos.',
			'itemTracker.errors.metadataKeyInvalid' => ({required Object key}) => 'La clave «${key}» no es válida.',
			'itemTracker.errors.metadataKeyDuplicated' => ({required Object key}) => 'La clave «${key}» está repetida.',
			'itemTracker.errors.metadataValueInvalid' => ({required Object key}) => 'El valor de «${key}» no es válido.',
			'itemTracker.errors.metadataTooMany' => 'Hay demasiados datos adicionales.',
			'itemTracker.errors.numberInvalid' => 'Escribe un número válido.',
			'itemTracker.errors.unexpected' => 'Ocurrió un error inesperado.',
			'itemTracker.errors.identifierNotFound' => 'El identificador ya no está asociado a este objeto.',
			_ => null,
		};
	}
}
