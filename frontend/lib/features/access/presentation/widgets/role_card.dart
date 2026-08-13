import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/access/models/role.dart';

/// One role in the list: what it is called, what it grants, and who holds it.
///
/// The three facts are the three questions asked about a role, in the order they are asked. The
/// administrator answers the middle one differently — «كل الصلاحيات», because its access comes
/// from a gate rule and its permission list is empty — and saying that plainly is what stops an
/// empty list reading as a broken role.
class RoleCard extends StatelessWidget {
  const RoleCard({required this.role, this.onTap, super.key});

  final Role role;
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              width: 1.5,
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              _Tile(role: role),
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
                            role.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (role.isSystem) ...[
                          SizedBox(width: 6.w),
                          // One word, no container: a system role is a fact about the role, not
                          // a warning, and a coloured badge would make the row read as a problem.
                          Text(
                            '· أساسي',
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      // The machine name, because it is what the API and the gate compare
                      // against — and it is the thing two similarly-labelled roles differ by.
                      role.name,
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
              SizedBox(width: 8.w),
              _Counts(role: role),
              if (onTap != null) ...[
                SizedBox(width: 4.w),
                Icon(AppIcons.forward, size: 18.sp, color: scheme.outline),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final side = 36.w;

    // The administrator is the one role whose access is unlimited, so it is the one that gets
    // the filled accent — everything else is a bundle somebody assembled.
    final isTotal = role.grantsEverything;

    return Container(
      height: side,
      width: side,
      decoration: BoxDecoration(
        color: isTotal ? scheme.primary : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Icon(
        isTotal ? AppIcons.adminRole : AppIcons.roles,
        size: 18.sp,
        color: isTotal ? scheme.onPrimary : scheme.onSecondaryContainer,
      ),
    );
  }
}

/// What it grants, and how many people hold it.
class _Counts extends StatelessWidget {
  const _Counts({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final grants = role.grantsEverything
        ? 'كل الصلاحيات'
        : role.hasPermissions
        ? '${role.permissions.length} صلاحية'
        : 'بلا صلاحيات';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
          decoration: BoxDecoration(
            // A role that grants nothing is not an offer, so it is muted rather than accented —
            // the same distinction a city with no agreed price makes on the delivery map.
            color: role.hasPermissions || role.grantsEverything
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(100.r),
          ),
          child: Text(
            grants,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: role.hasPermissions || role.grantsEverything
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          role.isHeld ? '${role.usersCount!.grouped} موظف' : 'لا أحد يحمله',
          style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
