import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/register_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/widgets/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// إنشاء حساب، بلغة شاشة الدخول نفسها ([AuthLayout]): الترويسة الكحلية، والبطاقة العائمة،
/// والحقول المعنونة.
///
/// **شاشةٌ لا يملكها تطبيق الموظفين.** حساب الموظف يُنشئه له مدير، خلف بوابةٍ لا يعبرها غير مدير؛
/// والعميل يُنشئ حسابه بنفسه. ثلاثة حقولٍ تُرسل ولا بريد — انظر [LoginPage] لسبب غيابه.
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

  /// إلى شاشة الدخول: رجوعٌ إليها إن كانت خلف هذه — وهي كذلك دائماً إلا حين تُفتح هذه وحدها من
  /// رابط، فتُفتح الدخول مكانها.
  void _toSignIn() => context.canPop() ? context.pop() : context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterCubit, RegisterState>(
      listener: (context, state) {
        switch (state) {
          case RegisterSuccess(:final session):
            // التسجيل يعيد جلسةً صالحة، فلا يتبعه تسجيل دخول — إلى الرئيسية مباشرةً.
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
          child: AuthLayout(
            title: 'أنشئ حسابك',
            subtitle: 'سجّل برقم هاتفك لتطلب وتتابع طلبياتك',
            prompt: 'لديك حساب؟',
            promptAction: 'سجّل الدخول',
            onPromptAction: _toSignIn,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _name,
                    label: 'الاسم',
                    hint: 'اسمك أو اسم متجرك',
                    validator: Validators.required,
                    autofillHints: const [AutofillHints.name],
                    errorText: state.nameError,
                    onChanged: (_) => context.read<RegisterCubit>().clearFailure(),
                  ),
                  SizedBox(height: 19.h),

                  AppTextField(
                    controller: _phone,
                    label: 'رقم الهاتف',
                    hint: '09X XXX XXXX',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: Validators.libyanPhone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    // هنا تهبط «رقم الهاتف مسجَّل مسبقاً. سجّل دخولك بدل إنشاء حساب» — الرفض
                    // الوحيد هنا الذي صاحبه يملك حساباً فعلاً لا أخطأ في الكتابة.
                    errorText: state.phoneError,
                    onChanged: (_) => context.read<RegisterCubit>().clearFailure(),
                  ),
                  SizedBox(height: 19.h),

                  AppTextField.password(
                    controller: _password,
                    hint: '٨ خانات على الأقل',
                    validator: Validators.password,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: state.passwordError,
                    onChanged: (_) => context.read<RegisterCubit>().clearFailure(),
                  ),
                  SizedBox(height: 19.h),

                  AppTextField.password(
                    controller: _confirm,
                    label: 'تأكيد كلمة المرور',
                    hint: '•••••••••',
                    // **يُقارَن هنا لا في الخادم.** الوجهة تطلب `password_confirmation` فعلاً،
                    // لكن عدم تطابقٍ يراه العميل لحظة يغادر الحقل أثمن من رحلةٍ تكلّفه واحدةً
                    // من ست محاولاتٍ في الدقيقة.
                    validator: (value) =>
                        value == _password.text ? null : 'تأكيد كلمة المرور لا يطابقها',
                    onSubmitted: (_) => _submit(),
                  ),
                  SizedBox(height: 23.h),

                  AppButton(label: 'إنشاء الحساب', isLoading: isSubmitting, onPressed: _submit),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
