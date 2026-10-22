import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Expone el idioma actual a todo el árbol. Se coloca por encima de
/// `MaterialApp` con `LocalizationCoordinator.languageCode`.
class LanguageScope extends InheritedNotifier<ValueListenable<String>> {
  const LanguageScope({
    super.key,
    required ValueListenable<String> languageCode,
    required super.child,
  }) : super(notifier: languageCode);

  /// Idioma actual; el widget que lo lee se reconstruye cuando cambia.
  static String of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LanguageScope>()
          ?.notifier
          ?.value ??
      '';
}

/// Vuelve a montar [child] cuando cambia el idioma de [LanguageScope].
///
/// Los textos de slang se leen de variables globales: un widget ya construido
/// no se entera del cambio de idioma (y los `const` ni siquiera se
/// reconstruyen). Envolver el contenido de cada página con este widget hace
/// que se monte de nuevo con los textos nuevos, sin tocar la pila de
/// navegación. Se pierde el estado de la página, aceptable para un cambio
/// tan poco frecuente.
class LanguageRebuilder extends StatelessWidget {
  const LanguageRebuilder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: ValueKey(LanguageScope.of(context)), child: child);
}
