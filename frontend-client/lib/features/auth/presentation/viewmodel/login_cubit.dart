import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/usecases/login.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_cubit.freezed.dart';
part 'login_state.dart';

/// The ViewModel for the sign-in screen.
///
/// It talks to a use case, never to a repository or to Dio, and it holds no `BuildContext` — a
/// Cubit that imports `material.dart` has stopped being testable without a widget tree.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required Login login})
    : _login = login,
      super(const LoginState.initial());

  final Login _login;

  Future<void> submit({required String phone, required String password}) async {
    // Ignored rather than queued: a second tap while the first request is in flight would issue
    // a second token and, on a slow connection, race the navigation that follows.
    if (state.isSubmitting) return;

    emit(const LoginState.submitting());

    final result = await _login(phone: phone, password: password);

    // The screen may have been popped while the request was in flight, and emitting into a
    // closed Cubit throws.
    if (isClosed) return;

    emit(result.fold(LoginState.failure, LoginState.success));
  }

  /// Clears a previous failure so the error under a field disappears as soon as the customer
  /// starts correcting it, rather than lingering until the next submit.
  void clearFailure() {
    if (state is LoginFailure) emit(const LoginState.initial());
  }
}
