import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Who is signed in, as the first thing on the screen.
///
/// It answers the question a shared workstation raises twenty times a day — *whose account is
/// this?* — before the numbers below it are read as anyone's.
///
/// The code is tappable because it is the one thing here that gets *typed somewhere else*: into
/// a paper form, a message, another system. Copying it beats re-reading it off the screen.
class EmployeeCard extends StatelessWidget {
  const EmployeeCard({required this.user, super.key});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [scheme.primary, scheme.tertiary],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(name: user.name),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                _EmployeeCode(code: user.employeeCode),
              ],
            ),
          ),
          if (user.roles.isNotEmpty) _RoleChip(label: user.roles.first.label),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    // `characters` rather than `[0]`: an Arabic letter with a mark on it, or an emoji, is more
    // than one code unit and slicing it produces a broken glyph.
    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;

    return Container(
      height: 56.w,
      width: 56.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colorScheme.onPrimary.withValues(alpha: 0.18),
        border: Border.all(color: context.colorScheme.onPrimary.withValues(alpha: 0.35)),
      ),
      child: Text(
        initial,
        style: context.textTheme.titleLarge?.copyWith(
          color: context.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmployeeCode extends StatelessWidget {
  const _EmployeeCode({required this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final foreground = scheme.onPrimary.withValues(alpha: 0.92);

    // An account created before the column existed. Saying so is better than showing "#null"
    // or an empty chip nobody can explain.
    if (code == null) {
      return Text(
        'لا يوجد كود موظف',
        style: context.textTheme.bodySmall?.copyWith(
          color: scheme.onPrimary.withValues(alpha: 0.7),
        ),
      );
    }

    return InkWell(
      onTap: () {
        unawaited(Clipboard.setData(ClipboardData(text: code!)));
        context.showSuccess('تم نسخ كود الموظف');
      },
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: scheme.onPrimary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'كود الموظف',
              style: context.textTheme.bodySmall?.copyWith(color: foreground),
            ),
            SizedBox(width: 6.w),
            Text(
              '#$code',
              // The number reads left-to-right even inside this right-to-left card.
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(AppIcons.copy, size: 14.sp, color: foreground),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: context.colorScheme.onPrimary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
