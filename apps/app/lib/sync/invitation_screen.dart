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
    final AppTranslations$app$sync$invitation$es invitationStrings = appStrings.app.sync.invitation;
    return Scaffold(
      appBar: AppTopBar(title: Text(invitationStrings.title)),
      body: BlocBuilder<InvitationCubit, String?>(
        builder: (BuildContext context, String? code) => code == null
            ? AppStatusView(icon: Icons.qr_code_2, title: invitationStrings.loading)
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
    final AppTranslations$app$sync$invitation$es invitationStrings = appStrings.app.sync.invitation;
    final InvitationCubit cubit = context.read<InvitationCubit>();
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.large),
              child: AppQrCode(data: code, semanticLabel: invitationStrings.qrLabel),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          invitationStrings.message,
          style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(invitationStrings.codeLabel, style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(code, style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            AppButton(
              label: invitationStrings.copy,
              icon: Icons.copy,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.medium,
              onPressed: () => _copy(context),
            ),
            if (cubit.canShare)
              AppButton(
                label: invitationStrings.share,
                icon: Icons.share,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.medium,
                onPressed: () => unawaited(cubit.share(subject: invitationStrings.title)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _WarningNote(invitationStrings.warning),
      ],
    );
  }
}

/// Aviso con fondo de advertencia. Un texto largo no cabe en un `AppBadge`.
class _WarningNote extends StatelessWidget {
  const _WarningNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.bgWarningSubtle, borderRadius: BorderRadius.circular(AppRadii.small)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s300),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(child: Icon(Icons.warning_amber_rounded, size: AppSizes.iconCompact, color: colors.textWarning)),
            const SizedBox(width: AppSpacing.s300),
            Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
