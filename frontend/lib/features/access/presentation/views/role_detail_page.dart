import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/presentation/viewmodel/role_detail_cubit.dart';
import 'package:dayaa/features/access/presentation/viewmodel/roles_cubit.dart';
import 'package:dayaa/features/access/presentation/widgets/permission_section.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One role, and **what it actually grants** — the screen this whole feature exists for.
///
/// A role's permissions arrive as one flat list of twenty-odd Arabic phrases. That is the same
/// information as the sections below and completely unreadable: nobody scanning it can answer
/// «does this role let somebody cancel an order?» without reading every line. So they are cut
/// into the catalogue's own sections, in the catalogue's own order — the same sections the
/// editor ticks them in, so what was granted is found where it was granted.
///
/// Three shapes, and the screen says which it is:
///   * **the administrator** — no permission rows at all, unlimited access by a gate rule, so
///     the sections are replaced by one card that says exactly that,
///   * **a role that grants nothing** — stated, with the way to fix it,
///   * **everything else** — the sections.
class RoleDetailPage extends StatelessWidget {
  const RoleDetailPage({required this.roleId, super.key});

  final int roleId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoleDetailCubit>(
      create: (_) => sl<RoleDetailCubit>(param1: roleId)..load(),
      child: const _RoleDetailView(),
    );
  }
}

class _RoleDetailView extends StatefulWidget {
  const _RoleDetailView();

  @override
  State<_RoleDetailView> createState() => _RoleDetailViewState();
}

/// Stateful for one reason: it remembers whether the role was renamed, re-permissioned or
/// deleted here, so `pop` can tell the list behind whether it is worth re-reading.
///
/// **A bool rather than the role itself**, and this is one of the two screens where that is the
/// honest answer: a delete leaves nothing to hand back, and `users_count` on the row behind is
/// the server's own counting. So the list is told *that* something moved and re-reads once —
/// instead of re-reading after every visit, including the ones that only looked.
class _RoleDetailViewState extends State<_RoleDetailView> {
  bool _changed = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoleDetailCubit>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Always through here, so the back button and the app bar's arrow return the same thing.
        context.pop(_changed);
      },
      child: BlocBuilder<RoleDetailCubit, RoleDetailState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text(switch (state) {
              RoleDetailLoaded(:final role) => role.label,
              _ => 'الدور',
            }),
            actions: [
              if (state is RoleDetailLoaded)
                _Actions(
                  role: state.role,
                  onChanged: () async {
                    _changed = true;
                    await cubit.refresh();
                  },
                  onDeleted: () {
                    _changed = true;
                    context.pop(true);
                  },
                ),
            ],
          ),
          body: switch (state) {
            RoleDetailLoading() => const Center(child: CircularProgressIndicator()),
            RoleDetailFailure(:final failure) => _FailureView(
              message: failure.message,
              onRetry: cubit.refresh,
            ),
            RoleDetailLoaded(:final role, :final groups) => RefreshIndicator(
              onRefresh: cubit.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
                children: [
                  _Summary(role: role),
                  SizedBox(height: 16.h),
                  if (role.grantsEverything)
                    const _GrantsEverythingCard()
                  else if (groups.isEmpty)
                    _NoPermissions(role: role)
                  else ...[
                    _SectionsHeading(role: role),
                    SizedBox(height: 8.h),
                    for (final group in groups) PermissionSection.readOnly(group: group),
                  ],
                ],
              ),
            ),
          },
        ),
      ),
    );
  }
}

/// Rename, re-permission, delete, and the history — each offered only when the **server** says
/// it is possible, never when a rule in this file says so.
class _Actions extends StatelessWidget {
  const _Actions({required this.role, required this.onChanged, required this.onDeleted});

  final Role role;
  final Future<void> Function() onChanged;

  /// Closes the screen — the role it was about no longer exists.
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RoleAction>(
      icon: Icon(AppIcons.more),
      onSelected: (action) => _run(context, action),
      itemBuilder: (context) => [
        // `canEditPermissions` is false for exactly one role — the administrator, whose access
        // is a gate rule rather than rows. Offering "edit" there would open a form whose save
        // the server refuses.
        if (role.canBeRenamed || role.canEditPermissions)
          const PopupMenuItem(value: _RoleAction.edit, child: Text('تعديل الدور')),
        const PopupMenuItem(value: _RoleAction.history, child: Text('سجل التعديلات')),
        if (role.canBeDeleted)
          PopupMenuItem(
            value: _RoleAction.delete,
            // Held by somebody: the server would refuse, so the row says why rather than
            // disappearing — «لماذا لا أستطيع الحذف؟» is a question the screen should answer.
            enabled: !role.isHeld,
            child: Text(
              role.isHeld ? 'حذف الدور (يحمله ${role.usersCount!.grouped})' : 'حذف الدور',
              style: TextStyle(
                color: role.isHeld ? null : context.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _run(BuildContext context, _RoleAction action) async {
    switch (action) {
      case _RoleAction.edit:
        // Re-read rather than taking the form's copy: this screen shows the permissions cut into
        // the catalogue's own sections, and that arrangement is built from the *detail* payload
        // the form does not return. The list behind is told once, on the way out.
        final saved = await context.push<Role>(Routes.editRole(role.id), extra: role);
        if (saved != null) await onChanged();

      case _RoleAction.history:
        await context.push(Routes.activityLog(AuditSubject.role, role.id), extra: role.label);

      case _RoleAction.delete:
        await _confirmDelete(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف «${role.label}»؟',
      description:
          'سيختفي الدور نهائياً. الصلاحيات نفسها لا تُحذف — هي جزء من النظام، وهذا الدور مجرد '
          'حزمة منها.',
    );

    if (confirmed != true || !context.mounted) return;

    // Deleting is the roles *list*'s operation, not this screen's: the answer is a list with one
    // row fewer, and this screen has nothing left to show afterwards. So it is performed by a
    // throwaway RolesCubit and the screen pops on success.
    final cubit = sl<RolesCubit>();
    final result = await cubit.delete(role);
    await cubit.close();

    if (!context.mounted) return;

    result.fold(
      // The server's own Arabic says which refusal it was — a role the code references, or one
      // somebody still holds. The app does not guess between them.
      context.showFailure,
      (message) {
        context.showSuccess(message);
        onDeleted();
      },
    );
  }
}

enum _RoleAction { edit, history, delete }

/// Who holds it, and what it is called to a machine.
class _Summary extends StatelessWidget {
  const _Summary({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            height: 44.w,
            width: 44.w,
            decoration: BoxDecoration(
              color: role.grantsEverything ? scheme.primary : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(
              role.grantsEverything ? AppIcons.adminRole : AppIcons.roles,
              size: 22.sp,
              color: role.grantsEverything ? scheme.onPrimary : scheme.onSecondaryContainer,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  role.label,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2.h),
                Text(
                  role.name,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  role.isHeld
                      ? 'يحمله ${role.usersCount!.grouped} من الموظفين'
                      : 'لا يحمله أحد حالياً',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The heading above the sections, carrying the one number that summarises them.
class _SectionsHeading extends StatelessWidget {
  const _SectionsHeading({required this.role});

  final Role role;

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
          '${role.permissions.length} صلاحية',
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// The administrator's answer, which is not a list.
class _GrantsEverythingCard extends StatelessWidget {
  const _GrantsEverythingCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.adminRole, size: 22.sp, color: scheme.onPrimaryContainer),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'يمنح كل الصلاحيات',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  // Said plainly, because an empty permission list on a role screen otherwise
                  // reads as a bug — and this one is empty on purpose.
                  'وصوله يأتي من قاعدة في الخادم، لا من صلاحيات محددة هنا. لذلك قائمته فارغة '
                  'ولا يمكن تعديلها — كل صلاحية تُضاف للنظام مستقبلاً يملكها تلقائياً.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A role that grants nothing — which is what every new role is until somebody says otherwise.
class _NoPermissions extends StatelessWidget {
  const _NoPermissions({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(AppIcons.roles, size: 40.sp, color: scheme.outline),
          SizedBox(height: 12.h),
          Text(
            'هذا الدور لا يمنح شيئاً بعد',
            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          Text(
            'من يحمله يرى التطبيق فارغاً. حدّد له صلاحيات ليصبح له معنى.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (role.canEditPermissions) ...[
            SizedBox(height: 14.h),
            FilledButton.icon(
              onPressed: () => context.push(Routes.editRole(role.id), extra: role),
              icon: Icon(AppIcons.edit),
              label: const Text('تحديد الصلاحيات'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: context.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
