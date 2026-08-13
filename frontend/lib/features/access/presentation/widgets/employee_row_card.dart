import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// One member of staff: who they are, their code, and the jobs they hold.
///
/// The roles are the whole reason this screen exists, so they are shown as they are — one chip
/// each, named — rather than counted. «٣ أدوار» is a number nobody can act on; «مدير المخزن ·
/// محاسب» answers the question that was actually asked.
///
/// Somebody with no roles yet is stated, not left blank: a new account holds nothing, and an
/// empty row looks like a row that failed to load.
///
/// **A stopped account stays in this list** rather than disappearing, because the screen that
/// puts it back is the one this row opens. It says so with a badge — the same «موقوف» word the
/// customer card uses, so the two lists mean one thing by it.
class EmployeeRowCard extends StatelessWidget {
  const EmployeeRowCard({required this.user, this.onTap, super.key});

  final AuthUser user;

  /// Opens the employee's own screen. Every reader of this list gets it: what each of them may
  /// *do* there is decided there, action by action.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(16.r);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              width: 1.5,
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _Avatar(user: user),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            // Only when it is *not* the normal case: a badge on every row stops
                            // being read.
                            if (!user.isActive) ...[
                              SizedBox(width: 6.w),
                              const _StoppedBadge(),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          // The number people are actually reached on, in Latin digits and
                          // left-to-right — a phone number reflowed by an RTL paragraph is a
                          // different number.
                          user.phone,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (user.employeeCode != null) ...[
                    SizedBox(width: 8.w),
                    _CodeBadge(code: user.employeeCode!),
                  ],
                  if (onTap != null) ...[
                    SizedBox(width: 4.w),
                    Icon(AppIcons.forward, size: 18.sp, color: scheme.outline),
                  ],
                ],
              ),
              SizedBox(height: 10.h),
              _Roles(user: user),
            ],
          ),
        ),
      ),
    );
  }
}

/// Said on the row, so somebody scanning the list sees who can no longer sign in without
/// opening each account.
class _StoppedBadge extends StatelessWidget {
  const _StoppedBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        'موقوف',
        style: context.textTheme.labelSmall?.copyWith(
          color: scheme.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final side = 40.w;

    // The administrator is the one account with unlimited access; the accent says so before the
    // role chip below is read. A stopped account takes neither accent — it agrees with the
    // badge beside the name rather than announcing a power it can no longer use.
    final isAdmin = user.isAdmin && user.isActive;

    return Container(
      height: side,
      width: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isAdmin ? scheme.primary : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        // The first letter of the name. `characters` rather than `[0]`, because an Arabic
        // grapheme is not one code unit and slicing it produces a box.
        user.name.characters.firstOrNull ?? '؟',
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: isAdmin ? scheme.onPrimary : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        '#$code',
        textDirection: TextDirection.ltr,
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The jobs this account holds, named.
class _Roles extends StatelessWidget {
  const _Roles({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    if (user.roles.isEmpty) {
      return Text(
        // Stated rather than left blank. A brand-new account really does hold nothing, and that
        // is the row most worth acting on — so it says so instead of looking unfinished.
        'بلا أدوار — لا يستطيع فعل شيء بعد',
        style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: [
        for (final role in user.roles)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Text(
              role.label,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}
