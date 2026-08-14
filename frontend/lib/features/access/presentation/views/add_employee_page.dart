import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/presentation/viewmodel/add_employee_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// موظف جديد — registering a colleague.
///
/// **Administrators only.** The route redirects anyone else away and the button that opens it is
/// not drawn for them; the boundary is `can:users.create` on the API, which is a gate ability
/// rather than a permission so that it cannot be ticked onto a role. See `Session.isAdmin`.
///
/// The roles are on this screen rather than a step after it, because an account created with no
/// role can sign in and do nothing — and making that a second trip through a second screen is
/// how it ends up being the normal outcome.
class AddEmployeePage extends StatelessWidget {
  const AddEmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddEmployeeCubit>(
      create: (_) => sl<AddEmployeeCubit>()..loadRoles(),
      child: const _AddEmployeeView(),
    );
  }
}

class _AddEmployeeView extends StatefulWidget {
  const _AddEmployeeView();

  @override
  State<_AddEmployeeView> createState() => _AddEmployeeViewState();
}

/// Stateful for the controllers and the form key alone — widget-lifecycle resources a Cubit
/// cannot dispose for it. Every ticked role lives in the Cubit, because it has to survive the
/// rebuild a 422 causes.
class _AddEmployeeViewState extends State<_AddEmployeeView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    context.read<AddEmployeeCubit>().submit(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddEmployeeCubit>();

    return BlocConsumer<AddEmployeeCubit, AddEmployeeState>(
      listenWhen: (previous, current) =>
          previous.created != current.created || previous.failure != current.failure,
      listener: (context, state) {
        final created = state.created;
        if (created != null) {
          // The code the server allocated, not the name that was typed: it is the number
          // colleagues will use to refer to this person, and this is the one moment somebody is
          // looking at the screen when it appears.
          context.showSuccess(
            'تم إنشاء حساب ${created.name}',
            details: created.employeeCode != null
                ? 'كود الموظف #${created.employeeCode}'
                : null,
          );
          context.pop(created);

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
          appBar: AppBar(title: const Text('موظف جديد')),
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
                SizedBox(height: 14.h),
                // Either identifier signs in, which is worth saying once rather than leaving
                // somebody to wonder why an email is required for a person who has none.
                const _Hint(
                  text: 'يستطيع الموظف تسجيل الدخول برقم هاتفه أو ببريده، وبكلمة المرور أدناه.',
                ),
                SizedBox(height: 14.h),
                AppTextField.password(
                  controller: _password,
                  label: 'كلمة المرور',
                  errorText: state.passwordError,
                  onChanged: (_) => cubit.clearFailure(),
                  validator: Validators.password,
                ),
                SizedBox(height: 14.h),
                AppTextField.password(
                  controller: _confirm,
                  label: 'تأكيد كلمة المرور',
                  onChanged: (_) => cubit.clearFailure(),
                  // Checked here as well as on the server, and this is the one field where that
                  // matters most: the administrator is typing a password for somebody who cannot
                  // see it, so a typo would not surface until that person's first shift.
                  validator: Validators.confirmPassword(() => _password.text),
                ),
                SizedBox(height: 24.h),
                _RolesSection(state: state, onToggle: cubit.toggleRole),
                SizedBox(height: 20.h),
                AppButton(
                  label: 'إنشاء الحساب',
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

/// The jobs the new account starts with.
class _RolesSection extends StatelessWidget {
  const _RolesSection({required this.state, required this.onToggle});

  final AddEmployeeState state;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'الأدوار',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              // Said plainly rather than left blank: an account with no role is allowed, and it
              // looks like a finished job while being the one row nobody can use.
              state.selectedRoles.isEmpty
                  ? 'اختياري — بلا أدوار لن يستطيع فعل شيء'
                  : '${state.selectedRoles.length} محدد',
              style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        if (state.rolesError != null) ...[
          SizedBox(height: 6.h),
          Text(
            state.rolesError!,
            style: context.textTheme.labelSmall?.copyWith(color: scheme.error),
          ),
        ],
        SizedBox(height: 10.h),
        if (state.isLoadingRoles && state.roles.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (state.roles.isEmpty)
          // The list failed, or there genuinely are none. Either way the account can still be
          // created and given its roles from the staff list afterwards, so this reports rather
          // than blocks.
          const _Hint(
            text: 'لا توجد أدوار لعرضها الآن — يمكن تحديدها لاحقاً من قائمة الموظفين.',
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
            ),
            child: Material(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16.r),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final role in state.roles)
                    _RoleChoice(
                      role: role,
                      isSelected: state.selectedRoles.contains(role.name),
                      onToggle: () => onToggle(role.name),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.role,
    required this.isSelected,
    required this.onToggle,
  });

  final Role role;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(
        role.label,
        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        // What holding this role would actually mean, in one line — the whole point of the
        // choice. The administrator's answer differs because its access is a gate rule.
        role.grantsEverything
            ? 'كل الصلاحيات'
            : role.hasPermissions
            ? '${role.permissions.length} صلاحية'
            : 'بلا صلاحيات — لا يمنح شيئاً بعد',
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
