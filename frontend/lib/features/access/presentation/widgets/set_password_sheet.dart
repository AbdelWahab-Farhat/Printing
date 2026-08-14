import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/access/presentation/viewmodel/employee_detail_cubit.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Setting a new password for a colleague who has forgotten theirs.
///
/// **The current password is not asked for, and cannot be**: the person typing is not the
/// account holder. What guards this is the administrator gate on the server — it is not a
/// permission and cannot be granted to a role.
///
/// **Both boxes are typed, and that is the whole point of the second one.** A password mistyped
/// on one's own form is discovered a second later; mistyped here it locks out somebody who never
/// saw what was typed, and nobody finds out until their next shift. The server confirms it too —
/// this check exists so the answer arrives before the request does.
///
/// Nothing about the password is kept: the sheet closes, the controllers are disposed, and the
/// Cubit it borrows holds only the account that came back.
Future<void> showSetPasswordSheet({required BuildContext context, required AuthUser user}) {
  final cubit = context.read<EmployeeDetailCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider<EmployeeDetailCubit>.value(
      value: cubit,
      child: _SetPasswordView(user: user),
    ),
  );
}

class _SetPasswordView extends StatefulWidget {
  const _SetPasswordView({required this.user});

  final AuthUser user;

  @override
  State<_SetPasswordView> createState() => _SetPasswordViewState();
}

class _SetPasswordViewState extends State<_SetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    // Not trimmed: a space is a character in a password, and storing something other than what
    // was typed and confirmed would lock the employee out by their manager's tidiness.
    final saved = await context.read<EmployeeDetailCubit>().setPassword(_password.text);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (saved) {
      context.showSuccess('تم تغيير كلمة مرور ${widget.user.name}');
      Navigator.of(context).pop();
    }
    // On failure the sheet stays open with both boxes as they were: the reason is on a snackbar
    // over the page behind, and closing would make it retypable only from scratch.
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تغيير كلمة المرور',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  // Said out loud, because this sheet is opened from a screen about one person
                  // and typed into by somebody who may have several open in mind.
                  'ستُغلق جلسات ${widget.user.name} المفتوحة، وسيدخل بكلمة المرور الجديدة.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 16.h),
                // `AppTextField.password`, which brings the reveal toggle with it — and the
                // toggle matters more here than anywhere else in the app: the person typing is
                // not the password's owner and cannot ask them what they meant.
                AppTextField.password(
                  controller: _password,
                  label: 'كلمة المرور الجديدة',
                  autofocus: true,
                  prefixIcon: AppIcons.password,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 12.h),
                AppTextField.password(
                  controller: _confirmation,
                  label: 'تأكيد كلمة المرور',
                  prefixIcon: AppIcons.password,
                  // The app's own «كلمتا المرور غير متطابقتين», the same words the registration
                  // form uses — a second phrasing of one rule is a second thing to keep in step.
                  validator: Validators.confirmPassword(() => _password.text),
                ),
                SizedBox(height: 16.h),
                AppButton(label: 'حفظ', isLoading: _isSaving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
