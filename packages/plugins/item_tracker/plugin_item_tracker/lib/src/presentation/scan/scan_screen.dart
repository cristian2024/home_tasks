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
      appBar: AppBar(title: Text(binding ? t.bindTitle : t.title)),
      body: BlocConsumer<ScanBloc, ScanState>(
        listenWhen: (ScanState previous, ScanState current) =>
            previous.outcome != current.outcome || previous.notice != current.notice,
        listener: _onStateChanged,
        builder: (BuildContext context, ScanState state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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
    return Semantics(
      label: t.modeLabel,
      container: true,
      child: SegmentedButton<ScanMode>(
        segments: <ButtonSegment<ScanMode>>[
          ButtonSegment<ScanMode>(
            value: ScanMode.camera,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(t.modeCamera),
          ),
          ButtonSegment<ScanMode>(value: ScanMode.nfc, icon: const Icon(Icons.nfc), label: Text(t.modeNfc)),
          ButtonSegment<ScanMode>(value: ScanMode.manual, icon: const Icon(Icons.keyboard), label: Text(t.modeManual)),
        ],
        selected: <ScanMode>{mode},
        showSelectedIcon: false,
        onSelectionChanged: (Set<ScanMode> selection) =>
            context.read<ScanBloc>().add(ScanModeChanged(selection.single)),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({required this.state});

  final ScanState state;

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$scan$es t = itemTrackerStrings.itemTracker.scan;
    final ScanBloc bloc = context.read<ScanBloc>();
    final AppButton useManual = AppButton(
      label: t.useManual,
      icon: Icons.keyboard,
      variant: AppButtonVariant.secondary,
      onPressed: () => bloc.add(const ScanModeChanged(ScanMode.manual)),
    );

    return switch (state.cameraPermission) {
      null => const AppLoadingView(),
      HardwarePermissionStatus.granted => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ClipRect(
                child: bloc.cameraScanner?.buildPreview(
                      context,
                      errorBuilder: (BuildContext context, ScanException error) => AppStatusView(
                        icon: Icons.videocam_off,
                        title: t.cameraError,
                        action: useManual,
                      ),
                    ) ??
                    const AppLoadingView(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(t.promptCamera, textAlign: TextAlign.center),
            ),
          ],
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
              AppButton(label: t.openSettings, onPressed: () => bloc.add(const ScanSettingsRequested())),
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
          onPressed: () => bloc.add(const ScanModeChanged(ScanMode.camera)),
        ),
        AppButton(
          label: t.useManual,
          icon: Icons.keyboard,
          variant: AppButtonVariant.secondary,
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
          action: AppButton(label: t.checkAgain, onPressed: () => bloc.add(const ScanNfcStatusRefreshed())),
        ),
      HardwareStatus.available => AppStatusView(
          icon: Icons.nfc,
          title: state.nfcReading ? t.nfcWaiting : t.promptNfc,
          action: state.nfcReading
              ? AppButton(
                  label: t.nfcCancel,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => bloc.add(const ScanNfcReadCancelled()),
                )
              : AppButton(
                  label: t.nfcStart,
                  icon: Icons.nfc,
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
      padding: const EdgeInsets.all(AppSpacing.md),
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
          const SizedBox(height: AppSpacing.md),
          AppSectionHeader(t.typeLabel),
          SegmentedButton<IdentifierType>(
            segments: <ButtonSegment<IdentifierType>>[
              for (final IdentifierType type in IdentifierType.values)
                ButtonSegment<IdentifierType>(value: type, label: Text(identifierTypeLabel(type))),
            ],
            selected: <IdentifierType>{_type},
            onSelectionChanged: (Set<IdentifierType> selection) => setState(() => _type = selection.single),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: binding ? t.bindSubmit : t.manualSubmit,
            icon: binding ? Icons.link : Icons.search,
            isLoading: lookingUp,
            expand: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
