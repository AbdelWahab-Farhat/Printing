import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/core/widgets/app_text_link.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/widgets/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// تسجيل الدخول برقم الهاتف وكلمة المرور، بتصميم «بطاقةٌ عائمة فوق ترويسةٍ كحلية» ([AuthLayout]).
///
/// **لا حقل بريدٍ إلكتروني، ولن يكون.** حساب العميل بلا بريدٍ أصلاً — وغيابه هو سبب ألا تعيش هذه
/// الحسابات في جدول `users` الذي يُلزم ببريدٍ فريد. انظر Docs/customer-app/CUSTOMER-APP-DESIGN.md §٢.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // يُنشأ هنا لا على مستوى التطبيق: الـ Cubit لهذه الشاشة ويُغلق معها. Cubit شاشةٍ مسجَّلٌ
    // كـ singleton يظلّ يبعث في تيارٍ ميت بعد أول تسجيل خروج.
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

/// ذو حالةٍ لسببٍ واحد: يملك [GlobalKey] واثنين من [TextEditingController].
///
/// وهذه **مواردُ عمرِ الويدجت لا حالةُ التطبيق** — يجب التخلّص منها، والـ Cubit ليس أداة تخلّص.
/// نقلُ `TextEditingController` إلى الـ ViewModel يجعله يستورد `flutter/widgets.dart`، فلا يُختبر
/// بلا ربط ويدجتات.
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
    // تُغلق لوحة المفاتيح أولاً كي لا يختفي الزر المضغوط للتوّ خلفها أثناء الطلب.
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    context.read<LoginCubit>().submit(
      phone: _phone.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        switch (state) {
          case LoginSuccess(:final session):
            context.showSuccess('أهلاً ${session.customer.name}');
            context.go(Routes.home);

          case LoginFailure(:final failure):
            // أخطاء الحقول تُرسم تحت حقولها، فتكرارها في توستٍ يقول الشيء نفسه مرتين. الحساب
            // الموقوف هو ما يصل هنا: يجيب بـ 403 ورسالةٍ بلا حقل.
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
          // يُقفل النموذج كله ما دام الطلب في الطريق — الحقول أيضاً — فما على الشاشة يطابق
          // دائماً ما أُرسل.
          absorbing: isSubmitting,
          child: AuthLayout(
            title: 'أهلاً بك مجدداً',
            subtitle: 'سجّل دخولك لمتابعة طلبياتك',
            prompt: 'ليس لديك حساب؟',
            promptAction: 'إنشاء حساب جديد',
            // **الطريق الذي لا مقابل له في تطبيق الموظفين.** حساب الموظف يُنشئه له مدير،
            // والعميل يُنشئ حسابه بنفسه.
            onPromptAction: () => context.push(Routes.register),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _phone,
                    label: 'رقم الهاتف',
                    // المثال بشكل التصميم وأرقام ليبيا: ما يبدأ بغير ٠٩ يرفضه المدقّق.
                    hint: '09X XXX XXXX',
                    keyboardType: TextInputType.phone,
                    // رقم الهاتف أرقام: غيرها خطأ طباعي، فترفضه لوحة المفاتيح بدل أن يشتكي
                    // النموذج بعده.
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: Validators.libyanPhone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    // شكوى الخادم عن هذا الحقل، إن اشتكى.
                    errorText: state.phoneError,
                    onChanged: (_) => context.read<LoginCubit>().clearFailure(),
                  ),
                  SizedBox(height: 19.h),

                  AppTextField.password(
                    controller: _password,
                    hint: '•••••••••',
                    // لا طريق لاستعادة كلمة المرور بعد — لا قناة رسائل في المشروع (خطة
                    // الميزات القادمة §٧) — فالرابط يقول ذلك بدل أن يفتح لا شيء.
                    labelAction: AppTextLink(
                      label: 'نسيتها؟',
                      onPressed: () => context.showInfo('ستتوفر قريباً'),
                    ),
                    validator: Validators.password,
                    autofillHints: const [AutofillHints.password],
                    errorText: state.passwordError,
                    onChanged: (_) => context.read<LoginCubit>().clearFailure(),
                    onSubmitted: (_) => _submit(),
                  ),
                  SizedBox(height: 23.h),

                  // `isLoading` لا `onPressed: null`: يحتفظ الزر بلونه ويُظهر الانتظار داخله بدل
                  // أن يشحب في منتصف الطلب. ورفض النقر شأنه هو.
                  AppButton(label: 'دخول', isLoading: isSubmitting, onPressed: _submit),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
