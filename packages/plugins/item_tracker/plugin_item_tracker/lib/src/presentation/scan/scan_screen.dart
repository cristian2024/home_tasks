import 'package:core_hardware/core_hardware.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import '../item_tracker_routes.dart';
import 'scan_bloc.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$scan$es t = itemTrackerStrings.itemTracker.scan;
    final bool binding = context.read<ScanBloc>().bindToItemId != null;
    return Scaffold(
      appBar: AppTopBar(title: Text(binding ? t.bindTitle : t.title)),
      body: BlocConsumer<ScanBloc, ScanState>(
        listenWhen: (ScanState previous, ScanState current) =>
            previous.outcome != current.outcome || previous.notice != current.notice,
        listener: _onStateChanged,
        builder: (BuildContext context, ScanState state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.s300),
              child: _ModeSelector(mode: state.mode),
            ),
            if (state.lookingUp)
              Semantics(
                label: binding ? t.binding : t.lookingUp,
                liveRegion: true,
                child: const LinearProgressIndicator(),
              ),
            Expanded(
              child: switch (state.mode) {
                ScanMode.camera => _CameraView(state: state),
                ScanMode.nfc => _NfcView(state: state),
                ScanMode.manual => const _ManualView(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStateChanged(BuildContext context, ScanState state) async {
    final ScanBloc bloc = context.read<ScanBloc>();
    final ScanNotice? notice = state.notice;
    if (notice != null) {
      final ItemTrackerTranslations$itemTracker$scan$es t = itemTrackerStrings.itemTracker.scan;
      final ItemTrackerTranslations$itemTracker$errors$es errors = itemTrackerStrings.itemTracker.errors;
      _showMessage(context, switch (notice) {
        ScanNotice.cameraError => t.cameraError,
        ScanNotice.readError => t.readError,
        ScanNotice.readCancelled => t.readCancelled,
        ScanNotice.invalidValue => errors.identifierInvalid,
        ScanNotice.itemNotFound => errors.itemNotFound,
        ScanNotice.unexpected => errors.unexpected,
      });
      bloc.add(const ScanNoticeShown());
    }

    final ScanOutcome? outcome = state.outcome;
    if (outcome == null) {
      return;
    }
    if (outcome.fromScanner) {
      // Anuncio para TalkBack / VoiceOver (§14.4).
      await SemanticsService.sendAnnouncement(
        View.of(context),
        itemTrackerStrings.itemTracker.scan.readAnnouncement(
          type: identifierTypeLabel(outcome.type),
          value: outcome.rawValue,
        ),
        Directionality.of(context),
      );
    }
    if (!context.mounted) {
      return;
    }
    final ({String rawValue, IdentifierType type}) identifier = (rawValue: outcome.rawValue, type: outcome.type);
    final String? itemId;
    switch (outcome) {
      case ScanItemFound():
        itemId = outcome.itemId;
      case ScanItemNotFound():
        // "No encontrado" devuelve el objeto creado o asociado, si lo hubo.
        itemId = await context.push<String>(ItemTrackerRoutes.withIdentifier(ItemTrackerRoutes.notFound, identifier));
      case ScanIdentifierBound():
        // Al cerrar la pantalla se cierra el bloc: no se le envía nada más.
        _showMessage(context, itemTrackerStrings.itemTracker.scan.bound);
        context.pop(outcome.itemId);
        return;
      case ScanBindRejected():
        // Se sigue escaneando: no se abre el otro objeto para no dejar la
        // cámara asociando lecturas por detrás.
        _showMessage(
          context,
          outcome.sameItem
              ? itemTrackerStrings.itemTracker.errors.alreadyBoundSame
              : itemTrackerStrings.itemTracker.scan.bindRejectedOther(name: outcome.boundItemName),
        );
        itemId = null;
    }
    if (itemId != null && context.mounted) {
      await context.push<void>(ItemTrackerRoutes.detail(itemId));
    }
    bloc.add(const ScanOutcomeHandled());
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode});

  final ScanMode mode;

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$scan$es t = itemTrackerStrings.itemTracker.scan;
    return AppChoiceSelector<ScanMode>(
      label: t.modeLabel,
      showLabel: false,
      padding: EdgeInsets.zero,
      options: <AppChoice<ScanMode>>[
        AppChoice<ScanMode>(value: ScanMode.camera, icon: Icons.qr_code_scanner, label: t.modeCamera),
        AppChoice<ScanMode>(value: ScanMode.nfc, icon: Icons.nfc, label: t.modeNfc),
        AppChoice<ScanMode>(value: ScanMode.manual, icon: Icons.keyboard, label: t.modeManual),
      ],
      selected: mode,
      onChanged: (ScanMode mode) => context.read<ScanBloc>().add(ScanModeChanged(mode)),
    );
  }
}

class _CameraView extends StatefulWidget {
  const _CameraView({required this.state});

  final ScanState state;

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> {
  /// La vista previa falló: su error ocupa el sitio del marco y del aviso.
  bool _previewFailed = false;

  void _markPreviewFailed() {
    if (!_previewFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _previewFailed = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$scan$es t = itemTrackerStrings.itemTracker.scan;
    final ScanBloc bloc = context.read<ScanBloc>();
    final ScanState state = widget.state;
    final AppButton useManual = AppButton(
      label: t.useManual,
      variant: AppButtonVariant.secondary,
      size: AppButtonSize.medium,
      onPressed: () => bloc.add(const ScanModeChanged(ScanMode.manual)),
    );
    return switch (state.cameraPermission) {
      null => const AppLoadingView(),
      HardwarePermissionStatus.granted => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.s0, AppSpacing.md, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s300,
            children: <Widget>[
              Expanded(child: _CameraPreview(failed: _previewFailed, onFailed: _markPreviewFailed, useManual: useManual)),
              if (!_previewFailed)
                Text(
                  t.promptCamera,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppThemeColors.of(context).textSecondary),
                ),
            ],
          ),
        ),
      HardwarePermissionStatus.denied => AppStatusView(
          icon: Icons.no_photography,
          title: t.cameraPermissionTitle,
          message: t.cameraPermissionMessage,
          action: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: <Widget>[
              AppButton(
                label: t.grantPermission,
                size: AppButtonSize.medium,
                onPressed: () => bloc.add(const ScanCameraPermissionRequested()),
              ),
              useManual,
            ],
          ),
        ),
      HardwarePermissionStatus.permanentlyDenied => AppStatusView(
          icon: Icons.no_photography,
          title: t.cameraPermissionTitle,
          message: t.cameraPermanentlyDeniedMessage,
          action: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: <Widget>[
              AppButton(
                label: t.openSettings,
                size: AppButtonSize.medium,
                onPressed: () => bloc.add(const ScanSettingsRequested()),
              ),
              useManual,
            ],
          ),
        ),
      HardwarePermissionStatus.restricted => AppStatusView(
          icon: Icons.block,
          title: t.cameraPermissionTitle,
          message: t.cameraRestrictedMessage,
          action: useManual,
        ),
    };
  }
}

/// La vista previa de la cámara en su marco. Si falla, muestra el error en su
/// lugar y avisa con [onFailed].
class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.failed, required this.onFailed, required this.useManual});

  final bool failed;
  final VoidCallback onFailed;
  final Widget useManual;

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$scan$es t = itemTrackerStrings.itemTracker.scan;
    final Widget view = context.read<ScanBloc>().cameraScanner?.buildPreview(
          context,
          errorBuilder: (BuildContext context, ScanException error) {
            onFailed();
            return AppStatusView(icon: Icons.videocam_off, title: t.cameraError, action: useManual);
          },
        ) ??
        const AppLoadingView();
    return failed ? view : AppCameraFrame(child: view);
  }
}

class _NfcView extends StatelessWidget {
  const _NfcView({required this.state});

  final ScanState state;

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$scan$es t = itemTrackerStrings.itemTracker.scan;
    final ScanBloc bloc = context.read<ScanBloc>();
    final Wrap alternatives = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: <Widget>[
        AppButton(
          label: t.modeCamera,
          icon: Icons.qr_code_scanner,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.medium,
          onPressed: () => bloc.add(const ScanModeChanged(ScanMode.camera)),
        ),
        AppButton(
          label: t.useManual,
          icon: Icons.keyboard,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.medium,
          onPressed: () => bloc.add(const ScanModeChanged(ScanMode.manual)),
        ),
      ],
    );

    return switch (state.nfcStatus) {
      null => const AppLoadingView(),
      // AC-06: sin NFC la opción se desactiva con un mensaje accesible.
      HardwareStatus.unsupported => AppStatusView(
          icon: Icons.nfc,
          title: t.nfcUnsupportedTitle,
          message: t.nfcUnsupportedMessage,
          action: alternatives,
        ),
      HardwareStatus.disabled => AppStatusView(
          icon: Icons.nfc,
          title: t.nfcDisabledTitle,
          message: t.nfcDisabledMessage,
          action: AppButton(
            label: t.checkAgain,
            size: AppButtonSize.medium,
            onPressed: () => bloc.add(const ScanNfcStatusRefreshed()),
          ),
        ),
      HardwareStatus.available => AppStatusView(
          icon: Icons.nfc,
          title: state.nfcReading ? t.nfcWaiting : t.promptNfc,
          action: state.nfcReading
              ? AppButton(
                  label: t.nfcCancel,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  onPressed: () => bloc.add(const ScanNfcReadCancelled()),
                )
              : AppButton(
                  label: t.nfcStart,
                  size: AppButtonSize.medium,
                  onPressed: state.lookingUp ? null : () => bloc.add(const ScanNfcReadRequested()),
                ),
        ),
    };
  }
}

class _ManualView extends StatefulWidget {
  const _ManualView();

  @override
  State<_ManualView> createState() => _ManualViewState();
}

class _ManualViewState extends State<_ManualView> {
  final TextEditingController _controller = TextEditingController();
  IdentifierType _type = IdentifierType.qr;
  bool _showEmptyError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();
    setState(() => _showEmptyError = value.isEmpty);
    if (value.isNotEmpty) {
      context.read<ScanBloc>().add(ScanManualSubmitted(rawValue: value, type: _type));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$scan$es t = itemTrackerStrings.itemTracker.scan;
    final bool lookingUp = context.select<ScanBloc, bool>((ScanBloc bloc) => bloc.state.lookingUp);
    final bool binding = context.read<ScanBloc>().bindToItemId != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.s0, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            label: t.manualLabel,
            hint: t.manualHint,
            controller: _controller,
            autofocus: true,
            maxLength: ItemValidator.maxIdentifierLength,
            textInputAction: TextInputAction.search,
            errorText: _showEmptyError ? itemTrackerStrings.itemTracker.errors.required : null,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.s300),
          AppSectionHeader(t.typeLabel),
          AppChoiceSelector<IdentifierType>(
            label: t.typeLabel,
            showLabel: false,
            wrapLabels: true,
            padding: EdgeInsets.zero,
            options: <AppChoice<IdentifierType>>[
              for (final IdentifierType type in IdentifierType.values)
                AppChoice<IdentifierType>(value: type, label: identifierTypeLabel(type)),
            ],
            selected: _type,
            onChanged: (IdentifierType type) => setState(() => _type = type),
          ),
          const SizedBox(height: AppSpacing.s300),
          AppButton(
            label: binding ? t.bindSubmit : t.manualSubmit,
            isLoading: lookingUp,
            expand: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
