import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/views/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Sign in with a phone number and a password.
///
/// **No email field, and there never will be one.** A customer account has no email at all —
/// that absence is the reason these accounts do not live in the `users` table, whose email
/// column is required and unique. See Docs/customer-app/CUSTOMER-APP-DESIGN.md §٢.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Created here rather than injected app-wide: the Cubit belongs to this screen and is closed
    // with it. A screen-scoped Cubit registered as a singleton keeps emitting into a dead stream
    // after the first sign-out.
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
/// would make it import `flutter/widgets.dart` and stop being testable without a widget binding.
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
    // Dismissed first so the button just pressed is not hidden behind the keyboard while the
    // request runs.
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
                context.showSuccess('أهلاً ${session.customer.name}');
                context.go(Routes.home);

              case LoginFailure(:final failure):
                // Field-level errors are rendered under their inputs, so showing them again in a
                // snackbar would say the same thing twice. A deactivated account is the case
                // that lands here: it answers 403 with a message and no field.
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
                            const BrandMark(),
                            SizedBox(height: 16.h),
                            Text(
                              'أهلاً بك',
                              textAlign: TextAlign.center,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'سجّل دخولك برقم هاتفك لمتابعة طلبياتك',
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
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

                            // `isLoading`, not `onPressed: null`: the button keeps its colour and
                            // shows the wait inside itself instead of greying out halfway through
                            // the request. Refusing the tap is its own job.
                            AppButton(
                              label: 'دخول',
                              isLoading: isSubmitting,
                              onPressed: _submit,
                            ),
                            SizedBox(height: 16.h),

                            // **The route the staff app has no equivalent of.** An employee's
                            // account is created for them by an administrator; a customer signs
                            // themselves up.
                            AppButton.tonal(
                              label: 'إنشاء حساب جديد',
                              onPressed: () => context.push(Routes.register),
                            ),
                            SizedBox(height: 24.h),

                            // **Stated, not linked.** The design puts «شروط الاستخدام» and
                            // «سياسة الخصوصية» here as links; neither document exists yet, and a
                            // link to nothing is worse on a sign-up screen than on any other —
                            // it is the one place somebody might actually go looking.
                            Text(
                              'بالمتابعة أنت توافق على شروط الاستخدام وسياسة الخصوصية',
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
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
