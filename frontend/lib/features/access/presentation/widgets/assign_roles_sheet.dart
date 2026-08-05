import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/presentation/viewmodel/user_roles_cubit.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Which jobs one person holds.
///
/// A sheet rather than a screen, because it is one question with a short answer: tick the roles,
/// save, and you are back on the list you were reading. A page for this would put a navigation
/// step on either side of four checkboxes.
///
/// Returns the updated [AuthUser] through `pop` when something was saved, and `null` when the
/// sheet was dismissed — so the list refreshes only when there is a reason to.
Future<AuthUser?> showAssignRolesSheet({
  required BuildContext context,
  required AuthUser user,
}) {
  return showModalBottomSheet<AuthUser>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<UserRolesCubit>(
      create: (_) =>
          sl<UserRolesCubit>(param1: user.id, param2: {for (final r in user.roles) r.name})
            ..load(),
      child: _AssignRolesView(user: user),
    ),
  );
}

class _AssignRolesView extends StatelessWidget {
  const _AssignRolesView({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UserRolesCubit>();

    return BlocConsumer<UserRolesCubit, UserRolesState>(
      listenWhen: (previous, current) =>
          previous.saved != current.saved || previous.failure != current.failure,
      listener: (context, state) {
        if (state.saved != null) {
          context.showSuccess('تم تحديث أدوار ${user.name}');
          // The server's answer goes back, not what was ticked: the roles it stored are the
          // ones the list behind this sheet must now show.
          Navigator.of(context).pop(state.saved);

          return;
        }

        if (state.failure != null) context.showFailure(state.failure!);
      },
      builder: (context, state) {
        final canSave = state.hasChangesAgainst(cubit.initialRoles);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, controller) => Column(
            // The footer's button is the sheet's one action, so it is a bar across the sheet —
            // the same as the save button on every form behind it. Centred, the Column left it
            // shrink-wrapped around two words and floating in the white space.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Handle(name: user.name),
              Expanded(
                child: state.isLoadingRoles && state.roles.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: controller,
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                        children: [
                          if (user.isAdmin) const _AdminNote(),
                          for (final role in state.roles)
                            _RoleChoice(
                              role: role,
                              isSelected: state.selected.contains(role.name),
                              onToggle: () => cubit.toggle(role.name),
                            ),
                          if (state.roles.isEmpty && !state.isLoadingRoles)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: Text(
                                'لا توجد أدوار بعد — أنشئ دوراً أولاً من شاشة الأدوار',
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                child: AppButton(
                  label: 'حفظ الأدوار',
                  isLoading: state.isSaving,
                  // Off until the selection differs from what they came in with: a save that
                  // would send the roles somebody already has is a request with nothing to say.
                  onPressed: canSave ? cubit.save : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      child: Column(
        children: [
          Container(
            height: 4.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: context.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'أدوار $name',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A standing note on the administrator's sheet.
///
/// Unticking `admin` here is a real and permitted action — it is how somebody stops being one —
/// but its effect is total, so the sheet says what it is rather than letting a checkbox imply
/// it is one grant among several.
class _AdminNote extends StatelessWidget {
  const _AdminNote();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'هذا الحساب مدير: يمر من كل الصلاحيات بقاعدة في الخادم، لا بما هو محدد هنا. '
        'إزالة دور «مدير» تُنهي ذلك فوراً.',
        style: context.textTheme.labelMedium?.copyWith(color: scheme.onTertiaryContainer),
      ),
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
    final scheme = context.colorScheme;

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        role.label,
        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        // What holding this role would actually mean, in one line — the whole point of the
        // choice. The administrator's answer is different because its access is a gate rule.
        role.grantsEverything
            ? 'كل الصلاحيات'
            : role.hasPermissions
            ? '${role.permissions.length} صلاحية'
            : 'بلا صلاحيات — لا يمنح شيئاً بعد',
        style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
