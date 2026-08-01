import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';

/// The two things staff start most often, one tap from the top of the screen.
///
/// Deliberately two, not a wall of shortcuts: a shortcut row stops being a shortcut once it
/// needs reading. Anything else lives in the tabs below, where it can be found by name.
class QuickActions extends StatelessWidget {
  const QuickActions({required this.actions, super.key});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, action) in actions.indexed) ...[
          if (index > 0) SizedBox(width: 12.w),
          Expanded(child: _QuickActionTile(action: action)),
        ],
      ],
    );
  }
}

/// One shortcut: what it says, what it looks like, and what it does.
class QuickAction {
  const QuickAction({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                height: 44.w,
                width: 44.w,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(action.icon, size: 22.sp, color: scheme.onPrimaryContainer),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
