import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/presentation/viewmodel/role_form_cubit.dart';
import 'package:dayaa/features/access/presentation/widgets/permission_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Creating a role, and editing one. The same screen — it is the same two questions.
///
/// The name is a **machine name**: lowercase Latin, digits, `-` and `_`, because the gate and
/// the code compare roles by this string. The server enforces it and this screen says so up
/// front rather than letting somebody type «محاسب أول» and meet a 422.
class RoleFormPage extends StatelessWidget {
  const RoleFormPage({this.role, super.key});

  /// The role being edited, carried from the screen that opened this one. `null` creates.
  final Role? role;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoleFormCubit>(
      create: (_) => sl<RoleFormCubit>()..load(editing: role),
      child: _RoleFormView(role: role),
    );
  }
}

class _RoleFormView extends StatefulWidget {
  const _RoleFormView({required this.role});

  final Role? role;

  @override
  State<_RoleFormView> createState() => _RoleFormViewState();
}

/// Stateful for the text controller and the form key alone — widget-lifecycle resources a Cubit
/// cannot dispose for it. Every ticked box lives in the Cubit, because it has to survive the
/// rebuild a 422 causes.
class _RoleFormViewState extends State<_RoleFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.role?.name ?? '',
  );

  bool get _isEditing => widget.role != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    context.read<RoleFormCubit>().submit(
      roleId: widget.role?.id,
      name: _name.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoleFormCubit>();

    return BlocConsumer<RoleFormCubit, RoleFormState>(
      listenWhen: (previous, current) =>
          previous.saved != current.saved || previous.failure != current.failure,
      listener: (context, state) {
        if (state.saved != null) {
          context.showSuccess(_isEditing ? 'تم حفظ الدور' : 'تم إنشاء الدور');
          // The saved role goes back, so whoever opened this screen sees what the *server*
          // stored rather than what was typed into it.
          context.pop(state.saved);

          return;
        }

        // A 422 keeps its message under the name box — see `RoleFormState.nameError`. Anything
        // else has nowhere to go but a snackbar.
        final failure = state.failure;
        if (failure != null && state.nameError == null && state.permissionsError == null) {
          context.showFailure(failure);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(_isEditing ? 'تعديل الدور' : 'دور جديد')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              children: [
                AppTextField(
                  controller: _name,
                  label: 'اسم الدور',
                  hint: 'accountant',
                  prefixIcon: AppIcons.tag,
                  errorText: state.nameError,
                  // Latin, and left-to-right, because that is the only thing the server will
                  // accept — an Arabic keyboard here produces a 422 every time.
                  textDirection: TextDirection.ltr,
                  enabled: widget.role?.canBeRenamed ?? true,
                  onChanged: (_) => cubit.clearFailure(),
                  validator: Validators.compose([
                    Validators.required,
                    Validators.minLength(2),
                    _machineName,
                  ]),
                ),
                SizedBox(height: 6.h),
                Text(
                  'أحرف إنجليزية صغيرة وأرقام وشرطات فقط — هذا الاسم للنظام، والاسم المعروض '
                  'يأتي منه.',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 20.h),
                _PermissionsHeading(state: state),
                if (state.permissionsError != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    state.permissionsError!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                if (state.isLoadingCatalogue && state.catalogue.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else
                  for (final group in state.catalogue)
                    PermissionSection.editable(
                      group: group,
                      isSelected: state.selected.contains,
                      selectedCount: state.selectedIn(group),
                      onToggle: cubit.toggle,
                      onToggleGroup: () => cubit.toggleGroup(group),
                    ),
                SizedBox(height: 8.h),
                AppButton(
                  label: _isEditing ? 'حفظ التعديلات' : 'إنشاء الدور',
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
                SizedBox(height: 8.h),
                Text(
                  // A role with nothing ticked is allowed, and is what «staff» already is — but
                  // it is worth saying out loud, because it looks like a finished job and is not.
                  state.selected.isEmpty
                      ? 'بلا صلاحيات: من يحمل هذا الدور لن يستطيع فعل شيء.'
                      : 'من يحمل هذا الدور سيستطيع تنفيذ ${state.selectedCount.grouped} إجراء.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// «الصلاحيات — ٧ من ٢٥ محددة»: the one number that says how far along this form is.
class _PermissionsHeading extends StatelessWidget {
  const _PermissionsHeading({required this.state});

  final RoleFormState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'الصلاحيات',
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          '${state.selectedCount.grouped} من ${state.catalogueCount.grouped} محددة',
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// The same shape the server enforces, checked here to save a round trip.
///
/// A service, not a guarantee: `StoreRoleRequest` validates it again and its 422 is the real
/// answer — this only puts the message next to the box.
String? _machineName(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return null;

  return RegExp(r'^[a-z0-9_-]+$').hasMatch(trimmed)
      ? null
      : 'أحرف إنجليزية صغيرة وأرقام وشرطات فقط';
}
