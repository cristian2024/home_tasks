import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Sombras del sistema de diseño de Figma (estilos `Elevation/*`), para
/// `BoxDecoration.boxShadow`.
abstract final class AppElevation {
  static const List<BoxShadow> light1 = <BoxShadow>[
    BoxShadow(color: AppColors.alphaViolet8, offset: Offset(0, 1), blurRadius: 3),
  ];

  static const List<BoxShadow> light2 = <BoxShadow>[
    BoxShadow(color: AppColors.alphaViolet8, offset: Offset(0, 4), blurRadius: 12, spreadRadius: -2),
  ];

  static const List<BoxShadow> light3 = <BoxShadow>[
    BoxShadow(color: AppColors.alphaViolet16, offset: Offset(0, 12), blurRadius: 28, spreadRadius: -6),
  ];

  static const List<BoxShadow> dark1 = <BoxShadow>[
    BoxShadow(color: AppColors.alphaBlack40, offset: Offset(0, 1), blurRadius: 3),
  ];

  static const List<BoxShadow> dark2 = <BoxShadow>[
    BoxShadow(color: AppColors.alphaBlack40, offset: Offset(0, 4), blurRadius: 12, spreadRadius: -2),
  ];

  static const List<BoxShadow> dark3 = <BoxShadow>[
    BoxShadow(color: AppColors.alphaBlack60, offset: Offset(0, 12), blurRadius: 28, spreadRadius: -6),
  ];
}
