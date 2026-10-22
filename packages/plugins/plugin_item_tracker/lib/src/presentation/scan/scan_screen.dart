import 'package:core_hardware/core_hardware.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/physical_identifier.dart';
import '../../domain/item_validator.dart';
import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import '../item_tracker_routes.dart';
import 'scan_bloc.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.scan;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocConsumer<ScanBloc, ScanState>(
        listenWhen: (previous, current) =>
            previous.outcome != current.outcome || previous.notice != current.notice,
        listener: _onStateChanged,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _ModeSelector(mode: state.mode),
            ),
            if (state.lookingUp)
              Semantics(
                label: t.lookingUp,
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
    final bloc = context.read<ScanBloc>();
    final notice = state.notice;
    if (notice != null) {
      final t = itemTrackerStrings.itemTracker.scan;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (notice) {
            ScanNotice.cameraError => t.cameraError,
            ScanNotice.readError => t.readError,
            ScanNotice.readCancelled => t.readCancelled,
            ScanNotice.invalidValue => itemTrackerStrings.itemTracker.errors.identifierInvalid,
            ScanNotice.unexpected => itemTrackerStrings.itemTracker.errors.unexpected,
          }),
        ),
      );
      bloc.add(const ScanNoticeShown());
    }

    final outcome = state.outcome;
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
    final identifier = (rawValue: outcome.rawValue, type: outcome.type);
    final itemId = switch (outcome) {
      ScanItemFound(:final itemId) => itemId,
      // "No encontrado" devuelve el objeto creado o asociado, si lo hubo.
      ScanItemNotFound() =>
        await context.push<String>(ItemTrackerRoutes.withIdentifier(ItemTrackerRoutes.notFound, identifier)),
    };
    if (itemId != null && context.mounted) {
      await context.push<void>(ItemTrackerRoutes.detail(itemId));
    }
    bloc.add(const ScanOutcomeHandled());
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode});

  final ScanMode mode;

  @override
  Widget build(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.scan;
    return Semantics(
      label: t.modeLabel,
      container: true,
      child: SegmentedButton<ScanMode>(
        segments: [
          ButtonSegment(value: ScanMode.camera, icon: const Icon(Icons.qr_code_scanner), label: Text(t.modeCamera)),
          ButtonSegment(value: ScanMode.nfc, icon: const Icon(Icons.nfc), label: Text(t.modeNfc)),
          ButtonSegment(value: ScanMode.manual, icon: const Icon(Icons.keyboard), label: Text(t.modeManual)),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => context.read<ScanBloc>().add(ScanModeChanged(selection.single)),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({required this.state});

  final ScanState state;

  @override
  Widget build(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.scan;
    final bloc = context.read<ScanBloc>();
    final useManual = AppButton(
      label: t.useManual,
      icon: Icons.keyboard,
      variant: AppButtonVariant.secondary,
      onPressed: () => bloc.add(const ScanModeChanged(ScanMode.manual)),
    );

    return switch (state.cameraPermission) {
      null => const AppLoadingView(),
      HardwarePermissionStatus.granted => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRect(
                child: bloc.cameraScanner?.buildPreview(
                      context,
                      errorBuilder: (context, error) => AppStatusView(
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
            children: [
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
            children: [
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
    final t = itemTrackerStrings.itemTracker.scan;
    final bloc = context.read<ScanBloc>();
    final alternatives = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
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
  final _controller = TextEditingController();
  IdentifierType _type = IdentifierType.qr;
  bool _showEmptyError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    setState(() => _showEmptyError = value.isEmpty);
    if (value.isNotEmpty) {
      context.read<ScanBloc>().add(ScanManualSubmitted(rawValue: value, type: _type));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.scan;
    final lookingUp = context.select<ScanBloc, bool>((bloc) => bloc.state.lookingUp);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            segments: [
              for (final type in IdentifierType.values)
                ButtonSegment(value: type, label: Text(identifierTypeLabel(type))),
            ],
            selected: {_type},
            onSelectionChanged: (selection) => setState(() => _type = selection.single),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: t.manualSubmit,
            icon: Icons.search,
            isLoading: lookingUp,
            expand: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
