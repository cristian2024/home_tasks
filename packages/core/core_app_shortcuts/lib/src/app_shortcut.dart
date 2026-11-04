import 'package:equatable/equatable.dart';

/// Un acceso rápido del icono de la app.
class AppShortcut extends Equatable {
  /// Lanza [ArgumentError] si [id] o [title] están en blanco, o si [iconName]
  /// no es `null` y está en blanco.
  AppShortcut({required this.id, required this.title, this.iconName}) {
    _checkNotBlank(id, 'id');
    _checkNotBlank(title, 'title');
    if (iconName != null) {
      _checkNotBlank(iconName!, 'iconName');
    }
  }

  /// Identificador que llega en `AppShortcutService.selections` al pulsarlo.
  final String id;

  /// Texto que muestra el lanzador, ya traducido.
  final String title;

  /// Nombre del recurso nativo del icono (Android `res/drawable`, iOS
  /// `Assets.xcassets`). Sin él, el acceso sale sin icono.
  final String? iconName;

  @override
  List<Object?> get props => <Object?>[id, title, iconName];
}

void _checkNotBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'No puede estar en blanco');
  }
}
