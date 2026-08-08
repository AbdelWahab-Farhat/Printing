import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';

/// The few things staff start most often, one tap from the top of the screen.
///
/// Still a short list, not a wall of shortcuts: a shortcut row stops being a shortcut once it
/// needs reading. Anything else lives in the tabs and the drawer, where it can be found by name.
///
/// **Two per row, and that is what changed when «إضافة عميل» became «عميل» and «مورد».** They
/// were laid out as one `Row` of `Expanded` tiles, which cannot overflow — it simply divides.
/// At three tiles each label was left about forty pixels, so «المخزن» would have arrived as
/// «الم…»: a shortcut nobody can read, failing silently. Wrapping keeps every tile the width two
/// tiles have always had, and puts the third on a line of its own.
class QuickActions extends StatelessWidget {
  const QuickActions({required this.actions, super.key});

  final List<QuickAction> actions;

  /// How many fit across. Two, matching the summary tiles directly beneath — the home screen
  /// reads as one grid rather than as a row that happens to sit above one.
  static const int _perRow = 2;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final rows = <List<QuickAction>>[
      for (var start = 0; start < actions.length; start += _perRow)
        actions.sublist(start, math.min(start + _perRow, actions.length)),
    ];

    return Column(
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) SizedBox(height: 12.h),
          Row(
            children: [
              for (var column = 0; column < _perRow; column++) ...[
                if (column > 0) SizedBox(width: 12.w),
                // An empty cell rather than a wider tile on a short last row: a lone shortcut
                // stretched across the screen reads as a different, more important kind of
                // thing than the two above it.
                Expanded(
                  child: column < row.length
                      ? _QuickActionTile(action: row[column])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
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
