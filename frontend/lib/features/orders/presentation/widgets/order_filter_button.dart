import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/widgets/order_status_chip.dart';

/// Picking which queue the list shows.
///
/// **A round button beside the search box, opening a sheet — not a row on the page.** Nine
/// queues do not fit as chips across a phone: that was tried first and did not survive contact
/// with the real vocabulary, the ones past «عند العميل» living off the right edge of a row
/// nothing suggested was scrollable. A dropdown that opened in place worked, but pushed the list
/// down every time it was used. A button costs one glance to notice and nothing from the layout
/// beneath it; the sheet it opens has room for all nine queues at once.
///
/// **Filled when a queue is picked, neutral on «الكل»**, so whether the list is narrowed is
/// answered before the sheet is even opened. The sheet itself carries the same per-row counts
/// the dropdown had — without them, learning there are no returns today cost a tap, a request
/// and an empty screen — plus a way back to «الكل» once something narrower is picked.
///
/// Colours come from the scheme, never from the design's hex values — the theme is generated
/// and gets replaced wholesale, and a literal here would survive that and quietly stop matching
/// everything around it.
class OrderFilterButton extends StatelessWidget {
  const OrderFilterButton({
    required this.selected,
    required this.counts,
    required this.onSelected,
    super.key,
  });

  final OrderQueue selected;
  final ValueListenable<OrderCounts> counts;
  final ValueChanged<OrderQueue> onSelected;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<OrderQueue>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Listens rather than reading once: the counts can still be in flight when the button is
      // tapped, and the sheet should not open frozen on the empty placeholder.
      builder: (_) => ValueListenableBuilder<OrderCounts>(
        valueListenable: counts,
        builder: (context, value, _) => _FilterSheet(selected: selected, counts: value),
      ),
    );

    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = selected != OrderQueue.all;

    return Material(
      color: isActive ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _open(context),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(13.w),
          child: Icon(
            AppIcons.filter,
            size: 22.sp,
            color: isActive ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.selected, required this.counts});

  final OrderQueue selected;
  final OrderCounts counts;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'تصفية الطلبيات',
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                // Only worth offering once there is something to clear — «الكل» already selected
                // means nothing is narrowed.
                if (selected != OrderQueue.all)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(OrderQueue.all),
                    child: const Text('مسح الفلاتر'),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            for (final queue in OrderQueue.values)
              _Row(
                queue: queue,
                count: counts.forQueue(queue),
                isSelected: queue == selected,
                // Picking a queue answers the sheet and closes it — there is nothing else to do
                // here, so a second confirmation tap would only be in the way.
                onTap: () => Navigator.of(context).pop(queue),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.queue,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final OrderQueue queue;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: isSelected ? scheme.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          child: Row(
            children: [
              // The dot carries the same colour the status chip on a card will have, so the
              // filter and the list agree without the reader having to learn two legends.
              Container(
                width: 9.w,
                height: 9.w,
                decoration: BoxDecoration(
                  color: _dotColour(scheme),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  queue.label,
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$count',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 8.w),
              // The slot is held whether or not it is filled, so the counts stay in one column
              // instead of shifting sideways as the selection moves.
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: isSelected
                    ? DecoratedBox(
                        decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, size: 11.sp, color: scheme.onPrimary),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// «الكل» has no status of its own, so it takes a neutral dot rather than borrowing one
  /// queue's colour and implying it means that queue.
  Color _dotColour(ColorScheme scheme) {
    final status = queue.statuses.firstOrNull;
    if (status == null) return scheme.outline;

    return OrderStatusChip.toneColour(scheme, status.tone).$2;
  }
}
