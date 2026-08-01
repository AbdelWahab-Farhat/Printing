import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/auth/presentation/viewmodel/login_cubit.dart';

/// Sign in with a phone number and a password.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Created here rather than injected app-wide: the Cubit belongs to this screen and is
    // closed with it. A screen-scoped Cubit registered as a singleton keeps emitting into a
    // dead stream after the first sign-out.
    return BlocProvider<LoginCubit>(
      create: (_) => sl<LoginCubit>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

/// Stateful for one reason: it owns a [GlobalKey] and two [TextEditingController]s.
///
/// Those are **widget-lifecycle resources, not application state** — they must be disposed, and
/// a Cubit is not a disposal mechanism. Moving a `TextEditingController` into the ViewModel
/// would make it import `flutter/widgets.dart` and stop being testable without a widget
/// binding, which is a far worse trade than a `State` class.
///
/// What is *not* here is anything the user's session depends on: that all lives in
/// [LoginCubit]. The rule is about where decisions are made, not about the keyword.
class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    // Dismissed first so the button the user just pressed is not hidden behind the keyboard
    // while the request runs.
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    context.read<LoginCubit>().submit(
      phone: _phone.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<LoginCubit, LoginState>(
          listener: (context, state) {
            switch (state) {
              case LoginSuccess(:final session):
                context.showSuccess('مرحباً ${session.user.name}');
                context.go(Routes.home);

              case LoginFailure(:final failure):
                // Field-level errors are rendered under their inputs, so showing them again in
                // a snackbar would say the same thing twice.
                if (state.phoneError == null && state.passwordError == null) {
                  context.showFailure(failure);
                }

              default:
                break;
            }
          },
          builder: (context, state) {
            final isSubmitting = state.isSubmitting;

            return AbsorbPointer(
              // Locks the whole form while a request is in flight — including the fields, so
              // what is on screen always matches what was sent.
              absorbing: isSubmitting,
              // Centred on the screen rather than pinned under the status bar: two fields and a
              // button left a third of the page empty below them, which reads as a screen that
              // failed to finish loading. `LayoutBuilder` + `minHeight` keeps it centred while
              // still scrolling once the keyboard takes the bottom half.
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 48.h),
                    child: Center(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _Header(),
                            SizedBox(height: 40.h),

                            AppTextField(
                              controller: _phone,
                              label: 'رقم الهاتف',
                              hint: '09XXXXXXXX',
                              prefixIcon: AppIcons.phone,
                              keyboardType: TextInputType.phone,
                              // A phone number is digits: anything else is a typo, so the
                              // keyboard refuses it rather than the form complaining afterwards.
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              // Latin digits read left-to-right even inside this RTL form.
                              textDirection: TextDirection.ltr,
                              validator: Validators.libyanPhone,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              // The server's own complaint about this field, if it made one.
                              errorText: state.phoneError,
                              onChanged: (_) => context.read<LoginCubit>().clearFailure(),
                            ),
                            SizedBox(height: 18.h),

                            AppTextField.password(
                              controller: _password,
                              hint: '••••••••',
                              validator: Validators.password,
                              autofillHints: const [AutofillHints.password],
                              errorText: state.passwordError,
                              onChanged: (_) => context.read<LoginCubit>().clearFailure(),
                              onSubmitted: (_) => _submit(),
                            ),
                            SizedBox(height: 32.h),

                            // `isLoading`, not `onPressed: null`: the button keeps its colour
                            // and shows the wait inside itself instead of greying out halfway
                            // through the request. Refusing the tap is its own job.
                            AppButton(
                              label: 'تسجيل الدخول',
                              isLoading: isSubmitting,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The real brand mark, cropped out of the printed catalogue — not a stand-in icon from
        // the Material set. Transparent behind, so it sits on whatever the surface colour is.
        Image.asset(
          'assets/images/logo.png',
          height: 96.w,
          width: 96.w,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 20.h),
        Text(
          'PrintX',
          textDirection: TextDirection.ltr,
          style: context.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'سجّل دخولك للمتابعة',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
