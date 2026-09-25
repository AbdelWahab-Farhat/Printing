import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/usecases/register.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_cubit.freezed.dart';
part 'register_state.dart';

/// The ViewModel for the sign-up screen.
///
/// **The staff app has no counterpart.** An employee account is created for them by an
/// administrator, behind `users.create`, which nothing but an administrator satisfies. A
/// customer signs themselves up, which is why this screen — and this Cubit — exist only here.
class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({required Register register})
    : _register = register,
      super(const RegisterState.initial());

  final Register _register;

  Future<void> submit({
    required String name,
    required String phone,
    required String password,
  }) async {
    // Ignored rather than queued: the endpoint is throttled at six a minute, and a second tap
    // would spend one of those attempts on a request the customer did not intend to make.
    if (state.isSubmitting) return;

    emit(const RegisterState.submitting());

    final result = await _register(name: name, phone: phone, password: password);

    if (isClosed) return;

    emit(result.fold(RegisterState.failure, RegisterState.success));
  }

  void clearFailure() {
    if (state is RegisterFailure) emit(const RegisterState.initial());
  }
}
