import 'package:bloc/bloc.dart';
import 'package:core_share/core_share.dart';
import 'package:sync_engine/sync_engine.dart';

/// Invitación del hogar actual para mostrarla como QR y como texto: `null`
/// mientras se prepara.
class InvitationCubit extends Cubit<String?> {
  InvitationCubit(HouseholdService households, {ShareService? share})
      : _share = share,
        super(null) {
    households.invitation().then(
      (HouseholdInvitation invitation) {
        if (!isClosed) {
          emit(invitation.encode());
        }
      },
      // Sin hogar (p. ej. se salió desde otra pantalla) no hay código.
      onError: (Object _) {},
    );
  }

  final ShareService? _share;

  /// Si hay un adaptador para compartir el código.
  bool get canShare => _share != null;

  /// Abre la hoja de compartir del sistema con el código, si ya está listo.
  Future<void> share({String? subject}) async {
    final String? code = state;
    if (code != null) {
      await _share?.shareText(code, subject: subject);
    }
  }
}
