import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/auth/usecases/get_current_user.dart';
import 'package:dayaa/features/auth/usecases/has_stored_session.dart';
import 'package:dayaa/features/auth/usecases/logout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_cubit.freezed.dart';
part 'splash_state.dart';

/// Decides where the app opens, and — the part that matters — refuses to guess.
///
/// **The bug this exists to fix.** The splash used to send anyone whose `/auth/me` failed to the
/// login screen. On a dropped connection that is a lie with consequences: the token is fine, the
/// session is fine, and the user is asked for a password they may not remember to get back into
/// an app they were already signed into. Worse, it is the exact moment the phone is least able
/// to complete a login.
///
/// So a failure is now read for *what it says*:
///
///   * **401** — the token is dead: revoked from another device, or expired. That is the only
///     answer that means "sign in again", and it is the only one that leads to the login screen.
///   * **anything else** — the server was not reached, or answered badly. The session is not in
///     question; the network is. The screen says so and offers to try again.
///
/// [abandon] is the way out of the second case for somebody who wants to sign in as another
/// person while the server is unreachable — otherwise a broken backend would trap them on a
/// retry screen with no exit.
class SplashCubit extends Cubit<SplashState> {
  SplashCubit({
    required HasStoredSession hasStoredSession,
    required GetCurrentUser getCurrentUser,
    required Logout logout,
  }) : _hasStoredSession = hasStoredSession,
       _getCurrentUser = getCurrentUser,
       _logout = logout,
       super(const SplashState.checking());

  /// Long enough to read the name, short enough not to feel like a delay.
  static const Duration minimumDisplay = Duration(milliseconds: 1200);

  final HasStoredSession _hasStoredSession;
  final GetCurrentUser _getCurrentUser;
  final Logout _logout;

  /// Runs the check. Called once on the first frame, and again by the retry button.
  Future<void> check() async {
    emit(const SplashState.checking());

    // No token at all: nothing to check, so do not spend a request finding that out.
    if (!_hasStoredSession()) {
      await Future<void>.delayed(minimumDisplay);
      if (isClosed) return;
      emit(const SplashState.signedOut());

      return;
    }

    // Started *before* the delay is awaited, so the two overlap: the wait is the slower of the
    // two rather than their sum.
    final pendingUser = _getCurrentUser();
    await Future<void>.delayed(minimumDisplay);
    final result = await pendingUser;

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => failure is UnauthorizedFailure
            ? const SplashState.signedOut()
            : SplashState.unreachable(failure),
        (_) => const SplashState.signedIn(),
      ),
    );
  }

  /// Give up on the stored session and go to the login screen deliberately.
  ///
  /// The token is cleared, so the next launch does not land back on this screen — which would
  /// be the whole point missed for somebody whose token really is the problem and whose server
  /// is answering something other than 401.
  Future<void> abandon() async {
    await _logout();

    if (isClosed) return;

    emit(const SplashState.signedOut());
  }
}
