import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_display/qr_display.dart';

import '../i18n/strings.g.dart';
import 'invitation_cubit.dart';

/// Código del hogar, para que otro dispositivo se una: como QR para
/// escanearlo y como texto para copiarlo o compartirlo.
class InvitationScreen extends StatelessWidget {
  const InvitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$invitation$es t = appStrings.app.sync.invitation;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocBuilder<InvitationCubit, String?>(
        builder: (BuildContext context, String? code) => code == null
            ? AppStatusView(icon: Icons.qr_code_2, title: t.loading)
            : _InvitationBody(code: code),
      ),
    );
  }
}

class _InvitationBody extends StatelessWidget {
  const _InvitationBody({required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appStrings.app.sync.invitation.copied)));
  }

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$sync$invitation$es t = appStrings.app.sync.invitation;
    final InvitationCubit cubit = context.read<InvitationCubit>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: AppQrCode(data: code, semanticLabel: t.qrLabel),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(t.message, style: textTheme.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        Text(t.codeLabel, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(code, style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            AppButton(
              label: t.copy,
              icon: Icons.copy,
              variant: AppButtonVariant.secondary,
              onPressed: () => _copy(context),
            ),
            if (cubit.canShare)
              AppButton(
                label: t.share,
                icon: Icons.share,
                variant: AppButtonVariant.secondary,
                onPressed: () => unawaited(cubit.share(subject: t.title)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppBadge(label: t.warning, tone: AppBadgeTone.warning, icon: Icons.lock_outline),
      ],
    );
  }
}
