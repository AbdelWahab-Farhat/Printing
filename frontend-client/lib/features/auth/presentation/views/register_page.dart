import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/register_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/views/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Create an account.
///
/// **A screen the staff app does not have.** An employee's account is made for them by an
/// administrator, behind a gate nothing but an administrator satisfies; a customer signs
/// themselves up. Three fields and no email — see [LoginPage] for why there is none.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegisterCubit>(
      create: (_) => sl<RegisterCubit>(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    context.read<RegisterCubit>().submit(
      name: _name.text,
      phone: _phone.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SafeArea(
        child: BlocConsumer<RegisterCubit, RegisterState>(
          listener: (context, state) {
            switch (state) {
              case RegisterSuccess(:final session):
                // Registration hands back a usable session, so nothing follows it with a
                // sign-in — straight to the home screen.
                context.showSuccess('أهلاً بك ${session.customer.name}');
                context.go(Routes.home);

              case RegisterFailure(:final failure):
                if (state.nameError == null &&
                    state.phoneError == null &&
                    state.passwordError == null) {
                  context.showFailure(failure);
                }

              default:
                break;
            }
          },
          builder: (context, state) {
            final isSubmitting = state.isSubmitting;

            return AbsorbPointer(
              absorbing: isSubmitting,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandMark(compact: true),
                      SizedBox(height: 28.h),

                      AppTextField(
                        controller: _name,
                        label: 'الاسم',
                        hint: 'اسمك أو اسم متجرك',
                        prefixIcon: AppIcons.person,
                        validator: Validators.required,
                        autofillHints: const [AutofillHints.name],
                        errorText: state.nameError,
                        onChanged: (_) => context.read<RegisterCubit>().clearFailure(),
                      ),
                      SizedBox(height: 18.h),

                      AppTextField(
                        controller: _phone,
                        label: 'رقم الهاتف',
                        hint: '09XXXXXXXX',
                        prefixIcon: AppIcons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        textDirection: TextDirection.ltr,
                        validator: Validators.libyanPhone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        // Where «رقم الهاتف مسجَّل مسبقاً. سجّل دخولك بدل إنشاء حساب» lands —
                        // the one refusal here that is a person who already has an account
                        // rather than a typo.
                        errorText: state.phoneError,
                        onChanged: (_) => context.read<RegisterCubit>().clearFailure(),
                      ),
                      SizedBox(height: 18.h),

                      AppTextField.password(
                        controller: _password,
                        label: 'كلمة المرور',
                        hint: '٨ خانات على الأقل',
                        validator: Validators.password,
                        autofillHints: const [AutofillHints.newPassword],
                        errorText: state.passwordError,
                        onChanged: (_) => context.read<RegisterCubit>().clearFailure(),
                      ),
                      SizedBox(height: 18.h),

                      AppTextField.password(
                        controller: _confirm,
                        label: 'تأكيد كلمة المرور',
                        hint: '••••••••',
                        // **Compared here rather than at the server.** The endpoint does ask for
                        // `password_confirmation`, but a mismatch the customer can see the
                        // instant they leave the field is worth more than a round trip that
                        // costs one of six attempts a minute.
                        validator: (value) => value == _password.text
                            ? null
                            : 'تأكيد كلمة المرور لا يطابقها',
                        onSubmitted: (_) => _submit(),
                      ),
                      SizedBox(height: 32.h),

                      AppButton(
                        label: 'إنشاء الحساب',
                        isLoading: isSubmitting,
                        onPressed: _submit,
                      ),
                    ],
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
