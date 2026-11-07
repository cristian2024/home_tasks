import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// Iconos del sistema de diseño: la familia lineal Lucide, en
/// `assets/fonts/Lucide.ttf`, con su licencia en `LICENSE-Lucide.txt`.
///
/// Solo están los que se usan. Para añadir uno, se busca su código en el
/// `codepoints.json` de la versión de Lucide de la fuente (1.69.0) y se
/// declara aquí con el nombre del icono. Los paquetes usan estas constantes,
/// nunca `Icons`, para poder cambiar de familia desde un solo sitio.
abstract final class AppIcons {
  static const String _family = 'Lucide';
  static const String _package = 'design_system';

  static const IconData arrowDown = IconData(0xe042, fontFamily: _family, fontPackage: _package);
  static const IconData arrowLeft = IconData(0xe048, fontFamily: _family, fontPackage: _package);
  static const IconData arrowUp = IconData(0xe04a, fontFamily: _family, fontPackage: _package);
  static const IconData arrowUpDown = IconData(0xe37d, fontFamily: _family, fontPackage: _package);
  static const IconData ban = IconData(0xe051, fontFamily: _family, fontPackage: _package);
  static const IconData barcode = IconData(0xe533, fontFamily: _family, fontPackage: _package);
  static const IconData box = IconData(0xe061, fontFamily: _family, fontPackage: _package);
  static const IconData calendar = IconData(0xe063, fontFamily: _family, fontPackage: _package);
  static const IconData cameraOff = IconData(0xe065, fontFamily: _family, fontPackage: _package);
  static const IconData check = IconData(0xe06c, fontFamily: _family, fontPackage: _package);
  static const IconData chevronDown = IconData(0xe06d, fontFamily: _family, fontPackage: _package);
  static const IconData chevronRight = IconData(0xe06f, fontFamily: _family, fontPackage: _package);
  static const IconData circleAlert = IconData(0xe077, fontFamily: _family, fontPackage: _package);
  static const IconData circleCheck = IconData(0xe226, fontFamily: _family, fontPackage: _package);
  static const IconData clock = IconData(0xe087, fontFamily: _family, fontPackage: _package);
  static const IconData copy = IconData(0xe09e, fontFamily: _family, fontPackage: _package);
  static const IconData download = IconData(0xe0b2, fontFamily: _family, fontPackage: _package);
  static const IconData ellipsisVertical = IconData(0xe0b7, fontFamily: _family, fontPackage: _package);
  static const IconData file = IconData(0xe0c0, fontFamily: _family, fontPackage: _package);
  static const IconData folderInput = IconData(0xe334, fontFamily: _family, fontPackage: _package);
  static const IconData history = IconData(0xe1f5, fontFamily: _family, fontPackage: _package);
  static const IconData hourglass = IconData(0xe296, fontFamily: _family, fontPackage: _package);
  static const IconData house = IconData(0xe0f5, fontFamily: _family, fontPackage: _package);
  static const IconData keyboard = IconData(0xe284, fontFamily: _family, fontPackage: _package);
  static const IconData layers = IconData(0xe529, fontFamily: _family, fontPackage: _package);
  static const IconData layoutGrid = IconData(0xe0ff, fontFamily: _family, fontPackage: _package);
  static const IconData link = IconData(0xe102, fontFamily: _family, fontPackage: _package);
  static const IconData list = IconData(0xe106, fontFamily: _family, fontPackage: _package);
  static const IconData listChecks = IconData(0xe1d0, fontFamily: _family, fontPackage: _package);
  static const IconData logOut = IconData(0xe10e, fontFamily: _family, fontPackage: _package);
  static const IconData messageCircle = IconData(0xe116, fontFamily: _family, fontPackage: _package);
  static const IconData nfc = IconData(0xe3c3, fontFamily: _family, fontPackage: _package);
  static const IconData palette = IconData(0xe1dd, fontFamily: _family, fontPackage: _package);
  static const IconData pause = IconData(0xe12e, fontFamily: _family, fontPackage: _package);
  static const IconData pencil = IconData(0xe1f9, fontFamily: _family, fontPackage: _package);
  static const IconData play = IconData(0xe13c, fontFamily: _family, fontPackage: _package);
  static const IconData plus = IconData(0xe13d, fontFamily: _family, fontPackage: _package);
  static const IconData qrCode = IconData(0xe1df, fontFamily: _family, fontPackage: _package);
  static const IconData refreshCw = IconData(0xe145, fontFamily: _family, fontPackage: _package);
  static const IconData refreshCwOff = IconData(0xe498, fontFamily: _family, fontPackage: _package);
  static const IconData scanLine = IconData(0xe258, fontFamily: _family, fontPackage: _package);
  static const IconData search = IconData(0xe151, fontFamily: _family, fontPackage: _package);
  static const IconData settings = IconData(0xe154, fontFamily: _family, fontPackage: _package);
  static const IconData share = IconData(0xe155, fontFamily: _family, fontPackage: _package);
  static const IconData share2 = IconData(0xe156, fontFamily: _family, fontPackage: _package);
  static const IconData shoppingCart = IconData(0xe15c, fontFamily: _family, fontPackage: _package);
  static const IconData slidersVertical = IconData(0xe162, fontFamily: _family, fontPackage: _package);
  static const IconData smartphone = IconData(0xe163, fontFamily: _family, fontPackage: _package);
  static const IconData stickyNote = IconData(0xe303, fontFamily: _family, fontPackage: _package);
  static const IconData tag = IconData(0xe17f, fontFamily: _family, fontPackage: _package);
  static const IconData textAlignStart = IconData(0xe185, fontFamily: _family, fontPackage: _package);
  static const IconData trash = IconData(0xe18d, fontFamily: _family, fontPackage: _package);
  static const IconData trash2 = IconData(0xe18e, fontFamily: _family, fontPackage: _package);
  static const IconData triangleAlert = IconData(0xe193, fontFamily: _family, fontPackage: _package);
  static const IconData unlink = IconData(0xe19c, fontFamily: _family, fontPackage: _package);
  static const IconData upload = IconData(0xe19e, fontFamily: _family, fontPackage: _package);
  static const IconData userMinus = IconData(0xe1a1, fontFamily: _family, fontPackage: _package);
  static const IconData videoOff = IconData(0xe1a6, fontFamily: _family, fontPackage: _package);
  static const IconData x = IconData(0xe1b2, fontFamily: _family, fontPackage: _package);

  /// Lucide no tiene el signo suelto que usa el diseño en las urgencias.
  static const IconData exclamation = Icons.priority_high;
}
