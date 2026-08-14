import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/auth/usecases/logout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'logout_cubit.freezed.dart';
part 'logout_state.dart';

/// Signing out, from wherever the button lives.
///
/// **There is no failure case, and that is the point.** The repository clears the token from the
/// device even when the request fails, so once this has run the person *is* signed out on this
/// phone — the only thing a failure changes is whether the server was told. Modelling that as a
/// `LogoutFailure` would leave the screen deciding whether to navigate, and a shared phone that
/// stays signed in because the wifi dropped is the outcome that actually matters.
class LogoutCubit extends Cubit<LogoutState> {
  LogoutCubit({required Logout logout}) : _logout = logout, super(const LogoutState.initial());

  final Logout _logout;

  Future<void> submit() async {
    // A second tap while the first request is in flight would fire a second navigation.
    if (state is LogoutSubmitting) return;

    emit(const LogoutState.submitting());

    final result = await _logout();

    if (isClosed) return;

    emit(LogoutState.signedOut(failure: result.fold((failure) => failure, (_) => null)));
  }
}
