import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Indicador de carga centrado, anunciado como "Cargando…".
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: commonStrings.common.loading,
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
