import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/core/widgets/app_dialog.dart';
import 'package:printing/core/widgets/app_speed_dial.dart';
import 'package:printing/core/widgets/copy_text.dart';
import 'package:printing/features/access/presentation/viewmodel/employee_detail_cubit.dart';
import 'package:printing/features/access/presentation/widgets/assign_roles_sheet.dart';
import 'package:printing/features/access/presentation/widgets/set_password_sheet.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Everything about one member of staff, and the things done to their account.
///
/// **The screen this list has been missing since it was written.** Tapping a row used to open
/// the roles sheet and nothing else, so a wrong phone number, a forgotten password and an
/// employee who had left were all unreachable from the app — the list said so in its own header.
///
/// **The screen reads; the dial writes**, the same division the customer screen makes. What is
/// different here is that the writes are guarded three different ways rather than one:
/// correcting details and stopping the account need `users.manage`, and resetting a password is
/// the administrator's alone. Each action is *absent* for somebody without it, never disabled —
/// a button that opens a refusal is worse than no button.
///
/// **The wage has no action of its own.** It is a field on «تعديل البيانات», beside the name and
/// the number, and shown there only to somebody holding `users.salary`. It reaches a different
/// endpoint than the rest of that form — see `EmployeeFormCubit` — but that is the ViewModel's
/// business and not something the person filling one screen should have to know.
class EmployeeDetailPage extends StatelessWidget {
  const EmployeeDetailPage({required this.userId, super.key});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmployeeDetailCubit>(
      create: (_) => sl<EmployeeDetailCubit>(param1: userId)..load(),
      child: const _EmployeeDetailView(),
    );
  }
}

class _EmployeeDetailView extends StatelessWidget {
  const _EmployeeDetailView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EmployeeDetailCubit>();

    return Scaffold(
      floatingActionButtonLocation: AppSpeedDial.location,
      appBar: AppBar(
        title: BlocBuilder<EmployeeDetailCubit, EmployeeDetailState>(
          // The name once it is known, so the bar stops saying something generic the moment it
          // can say something useful.
          builder: (context, state) => Text(state.user?.name ?? 'تفاصيل الموظف'),
        ),
      ),
      floatingActionButton: BlocBuilder<EmployeeDetailCubit, EmployeeDetailState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) return const SizedBox.shrink();

          return _Actions(user: user);
        },
      ),
      body: BlocConsumer<EmployeeDetailCubit, EmployeeDetailState>(
        listener: (context, state) {
          // A failure that arrived *beside* the employee — a rejected wage, a refused stop.
          // The page stays; the reason goes to a snackbar over it, because the sheet that
          // caused it is usually still open with the value in it.
          if (state case EmployeeDetailLoaded(:final failure?)) {
            context.showFailure(failure);
          }
        },
        builder: (context, state) => switch (state) {
          EmployeeDetailLoading() => const Center(child: CircularProgressIndicator()),
          EmployeeDetailFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: cubit.load,
          ),
          _ => RefreshIndicator(
            onRefresh: cubit.load,
            child: _Body(user: state.user!, isChanging: state.isChanging),
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.user, required this.isChanging});

  final AuthUser user;
  final bool isChanging;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // `always`, so pull-to-refresh works on a short page: one that cannot scroll is one that
      // cannot be refreshed.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
      children: [
        _Identity(user: user),
        SizedBox(height: 14.h),

        // First under the identity, and loud: a stopped account changes what every action
        // below it means.
        if (!user.isActive) ...[
          _StoppedBand(isChanging: isChanging),
          SizedBox(height: 14.h),
        ],

        _RolesCard(user: user),

        // **Absent, not empty, for a reader without `users.salary`** — the server omits the key
        // entirely for them, so there is nothing here to draw and no «—» implying there might
        // be. For a reader who does hold it, a null salary is «لم يُحدَّد», which is a real
        // answer and gets said out loud.
        if (sl<Session>().can(AppPermission.manageUserSalaries)) ...[
          SizedBox(height: 14.h),
          _SalaryCard(user: user),
        ],
      ],
    );
  }
}

/// Who this is: the avatar, the name over the two ways to reach them, and the employee code.
class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = user.isActive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30.r,
          // The administrator's accent, as the list card draws it — and grey once the account
          // is stopped, so the avatar agrees with the band underneath it.
          backgroundColor: !isActive
              ? scheme.surfaceContainerHigh
              : user.isAdmin
              ? scheme.primary
              : scheme.secondaryContainer,
          child: Text(
            // `characters`, not `[0]`: an Arabic grapheme is not one code unit, and slicing it
            // produces a box.
            user.name.characters.firstOrNull ?? '؟',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: !isActive
                  ? scheme.onSurfaceVariant
                  : user.isAdmin
                  ? scheme.onPrimary
                  : scheme.onSecondaryContainer,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2.h),
              // Tap to copy, for the reason the customer screen has it: the number gets pasted
              // into WhatsApp and the address into a message.
              CopyText(
                value: user.phone,
                copiedMessage: 'تم نسخ رقم الهاتف',
                icon: AppIcons.phone,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (user.email case final email?)
                CopyText(
                  value: email,
                  copiedMessage: 'تم نسخ البريد الإلكتروني',
                  icon: AppIcons.email,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        if (user.employeeCode case final code?) ...[
          SizedBox(width: 10.w),
          _CodeBadge(code: code, isActive: isActive),
        ],
      ],
    );
  }
}

/// The employee's number, in the corner an RTL row arrives at last.
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code, required this.isActive});

  final String code;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      height: 44.w,
      constraints: BoxConstraints(minWidth: 58.w, maxWidth: 108.w),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '#$code',
          // Digits and a hash: they read left-to-right even inside this RTL row.
          textDirection: TextDirection.ltr,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Said once, loudly, when the account can no longer sign in.
///
/// **Only in that direction.** A working account needs no band announcing that it works — a
/// badge on every screen stops being read, which is the whole reason this one is worth drawing.
class _StoppedBand extends StatelessWidget {
  const _StoppedBand({required this.isChanging});

  final bool isChanging;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(AppIcons.deactivate, size: 20.sp, color: scheme.onErrorContainer),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'هذا الحساب موقوف — لا يستطيع تسجيل الدخول',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
          if (isChanging)
            SizedBox(
              height: 16.w,
              width: 16.w,
              child: CircularProgressIndicator(strokeWidth: 2.w),
            ),
        ],
      ),
    );
  }
}

/// The jobs this account holds, named — the same chips the list row shows.
class _RolesCard extends StatelessWidget {
  const _RolesCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return _Card(
      title: 'الأدوار',
      child: user.roles.isEmpty
          ? Text(
              // Stated rather than left blank, exactly as the list row states it: a brand-new
              // account really does hold nothing, and that is the row most worth acting on.
              'بلا أدوار — لا يستطيع فعل شيء بعد',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final role in user.roles)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Text(
                      role.label,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// What this employee is paid a month — drawn only for a reader holding `users.salary`.
class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final salary = user.salary;

    return _Card(
      title: 'الراتب الشهري',
      child: Text(
        // «لم يُحدَّد» rather than «0 د.ل»: an account created before the wage was agreed is a
        // real state, and a nought would read as a wage of nothing.
        salary == null ? 'لم يُحدَّد' : '${groupedDecimal(salary)} د.ل',
        style: context.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: salary == null ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
    );
  }
}

/// A titled block. One shape for the sections of this screen, so they read as a set.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

/// Everything this screen does to the account, in the order somebody reaches for them.
class _Actions extends StatelessWidget {
  const _Actions({required this.user});

  final AuthUser user;

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<EmployeeDetailCubit>();
    final saved = await context.push(Routes.editEmployee(user.id), extra: user);

    // Only when something was actually saved: a form backed out of has changed nothing, and
    // re-reading anyway costs a request for the same answer.
    if (saved != null) await cubit.load();
  }

  Future<void> _roles(BuildContext context) async {
    final cubit = context.read<EmployeeDetailCubit>();
    final updated = await showAssignRolesSheet(context: context, user: user);

    if (updated != null) await cubit.load();
  }

  Future<void> _toggleActive(BuildContext context) async {
    final cubit = context.read<EmployeeDetailCubit>();
    final stopping = user.isActive;

    // Confirmed in the direction that takes something away, and only that one: starting an
    // account again is undone by one more tap, while stopping it ends every session the person
    // has open on their phone.
    if (stopping) {
      final confirmed = await showCustomDialog(
        context: context,
        title: 'إيقاف الحساب؟',
        description:
            'لن يستطيع «${user.name}» تسجيل الدخول، وستُغلق جلساته المفتوحة الآن. '
            'يبقى اسمه على كل ما سجّله، ويمكنك تشغيل الحساب مرة أخرى في أي وقت.',
        confirmLabel: 'إيقاف',
      );

      // Deliberately not `showDestructiveDialog`: nothing is being destroyed — the account and
      // everything it recorded survive, and one more tap undoes this — and a bin over a
      // reversible action is a lie. The same reasoning the customer screen records.
      if (confirmed != true) return;
    }

    await cubit.setActive(isActive: !stopping);
  }

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();

    return AppSpeedDial(
      actions: [
        AppAction(
          label: 'تعديل البيانات',
          icon: AppIcons.edit,
          tone: AppActionTone.primary,
          permission: AppPermission.manageUsers,
          onTap: _edit,
        ),
        AppAction(
          label: 'الأدوار والصلاحيات',
          icon: AppIcons.roles,
          tone: AppActionTone.primary,
          permission: AppPermission.manageUsers,
          onTap: _roles,
        ),
        // **Not an `AppAction.permission`, because there is no permission to name.** Resetting
        // somebody else's password is a Gate ability on the server — it cannot be ticked onto a
        // role — so the only honest question the app can ask is `isAdmin`, exactly as the
        // «موظف جديد» button on the list does.
        if (session.isAdmin)
          AppAction(
            label: 'تغيير كلمة المرور',
            icon: AppIcons.password,
            onTap: (context) => showSetPasswordSheet(context: context, user: user),
          ),
        // Absent on your own account rather than refused after the tap: stopping it would
        // revoke the token making the request and lock you out of the screen that undoes it.
        // The server refuses it too — a hidden button is a courtesy, a refused request is the
        // rule.
        if (!session.isSelf(user.id))
          AppAction(
            label: user.isActive ? 'إيقاف الحساب' : 'تشغيل الحساب',
            icon: user.isActive ? AppIcons.deactivate : AppIcons.activate,
            // Only the direction that takes something away wears the warning colour.
            tone: user.isActive ? AppActionTone.warning : AppActionTone.neutral,
            permission: AppPermission.manageUsers,
            onTap: _toggleActive,
          ),
        AppAction(
          label: 'سجل التغييرات',
          icon: AppIcons.history,
          // `logs.view`, not `users.manage`, and that is the server's own line: a history shows
          // what everyone has done. Managing an account does not make somebody an auditor.
          permission: AppPermission.viewActivityLogs,
          onTap: (context) => context.push(
            Routes.activityLog(AuditSubject.user, user.id),
            extra: user.name,
          ),
        ),
      ],
    );
  }
}

/// The first read failed and there is nothing to show. Retry, rather than a dead end.
class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 44.sp, color: context.colorScheme.error),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
