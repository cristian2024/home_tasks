import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';

/// Abre una hoja inferior que mide lo que su contenido, con su asa arriba. Si
/// no cabe, se desplaza. Se cierra arrastrándola o tocando fuera.
Future<T?> showAppBottomSheet<T>(BuildContext context, {required WidgetBuilder builder}) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.s300,
            children: <Widget>[const _SheetHandle(), builder(context)],
          ),
        ),
      ),
    );

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  static const Size _size = Size(32, 4);

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: _size.width,
          height: _size.height,
          margin: const EdgeInsets.only(top: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppThemeColors.of(context).borderStrong,
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
        ),
      );
}
