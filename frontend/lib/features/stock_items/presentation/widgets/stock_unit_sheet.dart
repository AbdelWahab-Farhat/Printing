import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Picks what a shelf is counted in — and makes sure whoever picks knows what it costs.
///
/// ⚠️ **Changing the unit does not convert the balance and does not relabel it. It discards it.**
/// The server empties every warehouse holding this item through a recorded «تسوية نقص», in the
/// old unit, before the unit moves. A dialog that said «سيُعاد تسمية الوحدة» would be describing
/// an endpoint that does not exist, and the first person to find out would be the one standing in
/// front of a shelf the app says is empty.
///
/// **The warning and the choice are one control on purpose.** Splitting them — a picker here, a
/// confirmation wired up by each caller — is how the second caller ships without the second half.
/// So this returns a unit **only** after the destructive dialog has been accepted, and every
/// screen that wants to move a unit goes through it.
///
/// Returns null when the sheet was dismissed, when the confirmation was declined, **and when the
/// unit the shelf already has was tapped** — the server treats that as a no-op, and asking
/// somebody to confirm zeroing a balance for a change that will not happen is the worst possible
/// reading of this endpoint.
Future<StockUnit?> showStockUnitSheet({required BuildContext context, required StockItem item}) {
  return showModalBottomSheet<StockUnit>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _StockUnitSheet(item: item),
  );
}

class _StockUnitSheet extends StatelessWidget {
  const _StockUnitSheet({required this.item});

  final StockItem item;

  Future<void> _pick(BuildContext context, StockUnit unit) async {
    // Nothing to warn about and nothing to send: re-picking what is already selected changes no
    // row on the server and must not put a destructive dialog in front of anybody.
    if (unit == item.unit) {
      Navigator.of(context).pop();

      return;
    }

    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'تصفير رصيد «${item.displayName}»؟',
      description:
          'سيُصفَّر رصيد هذا الصنف في كل مخزن يحتويه، عبر «تسوية نقص» تُسجَّل باسمك في سجل '
          'الحركات قبل أن تتغير الوحدة. الكمية لا تُحوَّل ولا يُعاد تسميتها.\n\n'
          'بعد التغيير أعد جرد ما على الرفوف وسجّله بـ «${unit.label}». '
          'المخازن التي لا تحتوي شيئاً تتغير وحدتها دون أي حركة.',
      confirmLabel: 'تصفير الرصيد وتغيير الوحدة',
    );

    if (confirmed != true || !context.mounted) return;

    Navigator.of(context).pop(unit);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      // The drag handle above already clears the top.
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'وحدة تخزين «${item.displayName}»',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4.h),
            Text(
              // The server's own Arabic for what the shelf says today.
              'تُحسب الكمية الآن بـ «${item.unitLabel}»',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 14.h),
            const _Warning(),
            SizedBox(height: 14.h),
            for (final unit in StockUnit.choices) ...[
              _UnitOption(
                unit: unit,
                isCurrent: unit == item.unit,
                onTap: () => _pick(context, unit),
              ),
              SizedBox(height: 8.h),
            ],
          ],
        ),
      ),
    );
  }
}

/// Said before the choice is made, not after it.
///
/// A person who reads only the option they are about to tap must still have crossed this
/// sentence on the way to it — which is why it sits above the two rows rather than under them.
class _Warning extends StatelessWidget {
  const _Warning();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.error, size: 18.sp, color: scheme.onErrorContainer),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              // Latin digits, like every other number this app draws — see `core/utils/digits`.
              'تغيير الوحدة لا يحوّل الكمية، بل يصفّرها. 200 كيس ليست 200 كيلوغرام، وما على '
              'الرفوف اليوم لا معنى له بالوحدة الجديدة.',
              style: context.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One unit, and whether it is the one the shelf already has.
class _UnitOption extends StatelessWidget {
  const _UnitOption({required this.unit, required this.isCurrent, required this.onTap});

  final StockUnit unit;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(14.r);

    return Material(
      color: isCurrent ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: isCurrent ? Colors.transparent : scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  unit.label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? scheme.onPrimaryContainer : scheme.onSurface,
                  ),
                ),
              ),
              if (isCurrent)
                Text(
                  'الحالية',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
