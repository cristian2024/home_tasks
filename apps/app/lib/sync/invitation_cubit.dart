import 'package:bloc/bloc.dart';
import 'package:sync_engine/sync_engine.dart';

/// Invitación del hogar actual para mostrarla como QR: `null` mientras se
/// prepara.
class InvitationCubit extends Cubit<String?> {
  InvitationCubit(HouseholdService households) : super(null) {
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
}
