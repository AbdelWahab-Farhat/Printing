// `show`, because dartz exports a `State` of its own (its state monad) that collides with
// Flutter's the moment both are imported into a widget file. Only the option type is wanted.
import 'package:dartz/dartz.dart' show None, Some;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/access/presentation/viewmodel/employee_form_cubit.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Correcting an employee's details.
///
/// **Four boxes, and the last one is not always drawn.** The wage sits here beside the name and
/// the number, because that is where somebody looks for it — but only for a reader holding
/// `users.salary`, and it leaves by a different endpoint than the other three. See
/// `EmployeeFormCubit` for how one «حفظ» becomes two requests, and EMPLOYEE-DETAIL-DESIGN.md §٢
/// for why the server keeps them apart.
///
/// **The password and the roles are still absent**, and that is the design: both are decided
/// elsewhere by people who may not be this one. A form carrying a password field would put a
/// credential reset behind `users.manage`.
///
/// **A separate page rather than a mode of the registration form**, for the same reason: a
/// shared widget would keep the password controllers alive on a screen that must never send
/// them, one `if` away from doing so.
///
/// Pops with the saved [AuthUser] so the screen behind knows to re-read, and with nothing when
/// the form is backed out of.
class EmployeeFormPage extends StatelessWidget {
  const EmployeeFormPage({required this.user, super.key});

  /// The employee as the screen that opened this already had them — so the boxes are filled
  /// before any request comes back, and there is nothing to wait for on the way in.
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmployeeFormCubit>(
      create: (_) => sl<EmployeeFormCubit>(),
      child: _EmployeeFormView(user: user),
    );
  }
}

class _EmployeeFormView extends StatefulWidget {
  const _EmployeeFormView({required this.user});

  final AuthUser user;

  @override
  State<_EmployeeFormView> createState() => _EmployeeFormViewState();
}

/// Stateful for the controllers and the form key alone — widget-lifecycle resources a Cubit
/// cannot dispose for it.
class _EmployeeFormViewState extends State<_EmployeeFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _email = TextEditingController(text: widget.user.email ?? '');
  late final _salary = TextEditingController(text: widget.user.salary ?? '');

  /// Whether the wage is this reader's business at all. Read once: a permission does not change
  /// while a form is open, and re-asking on every rebuild would draw a box that could vanish
  /// mid-edit.
  final bool _showsSalary = sl<Session>().can(AppPermission.manageUserSalaries);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _salary.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    context.read<EmployeeFormCubit>().submit(
      userId: widget.user.id,
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      // `none()` when the box was never on screen, and when it was but nothing was typed into
      // it — so the ordinary edit of a phone number stays one request, and a reader who cannot
      // see wages never sends one the server would refuse.
      salary: _showsSalary && _salary.text.trim() != (widget.user.salary ?? '')
          ? Some(_salary.text)
          : const None(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EmployeeFormCubit>();

    return BlocConsumer<EmployeeFormCubit, EmployeeFormState>(
      listenWhen: (previous, current) =>
          previous.saved != current.saved || previous.failure != current.failure,
      listener: (context, state) {
        final saved = state.saved;
        if (saved != null) {
          context.showSuccess('تم تحديث بيانات ${saved.name}');
          context.pop(saved);

          return;
        }

        // A 422 is already marked under the boxes it is about; a red bar over them would be the
        // same news twice. Anything else — a refusal, a dropped connection — has nowhere else
        // to go.
        final failure = state.failure;
        if (failure != null && !state.isFieldFailure) context.showFailure(failure);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('تعديل بيانات الموظف')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              children: [
                AppTextField(
                  controller: _name,
                  label: 'الاسم',
                  hint: 'الاسم كما يُنادى به',
                  prefixIcon: AppIcons.person,
                  errorText: state.nameError,
                  onChanged: (_) => cubit.clearFailure(),
                  validator: Validators.compose([
                    Validators.required,
                    Validators.minLength(3),
                  ]),
                ),
                SizedBox(height: 14.h),
                AppTextField(
                  controller: _phone,
                  label: 'رقم الهاتف',
                  hint: '09XXXXXXXX',
                  prefixIcon: AppIcons.phone,
                  errorText: state.phoneError,
                  keyboardType: TextInputType.phone,
                  // Latin digits, left to right: a phone number reflowed by an RTL paragraph is
                  // a different number, and the server wants the western digits anyway.
                  textDirection: TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => cubit.clearFailure(),
                  validator: Validators.libyanPhone,
                ),
                SizedBox(height: 14.h),
                AppTextField(
                  controller: _email,
                  label: 'البريد الإلكتروني',
                  hint: 'name@dayaa.ly',
                  prefixIcon: AppIcons.email,
                  errorText: state.emailError,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  onChanged: (_) => cubit.clearFailure(),
                  validator: Validators.compose([Validators.required, Validators.email]),
                ),
                // **Beside the rest, not behind an action of its own**, because it is one of
                // the things somebody sits down to correct. Absent entirely for a reader
                // without `users.salary`: the server never sent them a figure to edit.
                if (_showsSalary) ...[
                  SizedBox(height: 14.h),
                  AppTextField(
                    controller: _salary,
                    label: 'الراتب الشهري',
                    hint: 'المبلغ بالدينار',
                    prefixIcon: AppIcons.salary,
                    errorText: state.salaryError,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textDirection: TextDirection.ltr,
                    // Latin digits and one separator: a wage typed in Arabic-Indic digits
                    // reaches the server as text it refuses, and the shop reads Latin ones.
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (_) => cubit.clearFailure(),
                    // No `required`: an empty box is «لم يُحدَّد», which is a state a wage can
                    // genuinely be in and has to stay reachable once a figure typed by mistake
                    // is in there.
                    helperText: 'اتركه فارغاً إن لم يُحدَّد راتب بعد',
                  ),
                ],
                SizedBox(height: 14.h),
                // Said once, because both boxes above are how somebody signs in — changing
                // either changes what this person types at the login screen.
                _Hint(
                  text:
                      'يسجّل ${widget.user.name} الدخول برقم هاتفه أو ببريده — تغيير أيّهما '
                      'يغيّر ما يُدخله. كلمة المرور لا تتغيّر من هنا.',
                ),
                SizedBox(height: 24.h),
                AppButton(
                  label: 'حفظ التعديلات',
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A quiet line of explanation under the fields it is about.
class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.about, size: 16.sp, color: scheme.onSurfaceVariant),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
