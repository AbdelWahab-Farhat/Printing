import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/auth/usecases/has_stored_session.dart';
import 'package:dayaa_client/features/auth/usecases/logout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_cubit.freezed.dart';
part 'splash_state.dart';

/// Decides where the app opens, and — the part that matters — refuses to guess.
///
/// Ported from the staff app, where it fixed a real complaint: with the connection down, a
/// signed-in user was dropped at the login screen and asked for a password to fix something that
/// was never about their password. Before this screen the client app did not guess wrong so much
/// as not ask at all — it trusted any stored token and opened home, where each section then
/// failed on its own.
///
/// So the token is checked once, up front, and a failure is read for *what it says*:
///
///   * **401** — the token is dead: revoked from another device, or expired. That is the only
///     answer that means "sign in again", and it is the only one that leads to the login screen.
///   * **anything else** — the server was not reached, or answered badly. The session is not in
///     question; the network is. The screen says so and offers to try again.
///
/// [abandon] is the way out of the second case for somebody who wants to sign in as another
/// customer while the server is unreachable — otherwise a broken backend would trap them on a
/// retry screen with no exit.
class SplashCubit extends Cubit<SplashState> {
  SplashCubit({
    required HasStoredSession hasStoredSession,
    required GetCurrentCustomer getCurrentCustomer,
    required Logout logout,
  }) : _hasStoredSession = hasStoredSession,
       _getCurrentCustomer = getCurrentCustomer,
       _logout = logout,
       super(const SplashState.checking());

  /// Long enough to read the name, short enough not to feel like a delay.
  static const Duration minimumDisplay = Duration(milliseconds: 1200);

  final HasStoredSession _hasStoredSession;
  final GetCurrentCustomer _getCurrentCustomer;
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
    final pendingCustomer = _getCurrentCustomer();
    await Future<void>.delayed(minimumDisplay);
    final result = await pendingCustomer;

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
