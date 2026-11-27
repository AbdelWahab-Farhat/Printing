import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The branch counter's board — INSTANT-ORDERS-PLAN.md §11, §12 «الرئيسية».
///
/// «طلب فوري» first, then what is waiting at the counter: the instant orders that are «جديدة» or
/// «تم الاستلام», and the late ones. Each card opens the list it counts.
///
/// **Only the two statuses the counter works** (owner's call, 2026-11-27): «إلغاء تام» and
/// «تم التسوية» are finished business, and the «استلام مكتب» card was dropped with them. The
/// server still sends every status; this board picks its two. Hiding a card never hides an
/// order: the search on the orders tab still finds every one.
class InstantBoardSection extends StatelessWidget {
  const InstantBoardSection({
    required this.board,
    required this.onNewOrder,
    required this.onOpenStatus,
    required this.onOpenLate,
    super.key,
  });

  /// The statuses drawn as cards, in this order.
  static const shownStatuses = ['new', 'delivered'];

  final InstantBoard board;
  final VoidCallback onNewOrder;
  final ValueChanged<OrderStatusCount> onOpenStatus;
  final VoidCallback onOpenLate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (board.canCreate) ...[
          AppButton(
            label: 'طلب فوري',
            icon: AppIcons.add,
            // Drawn disabled rather than hidden, with the reason under it: an employee with the
            // grant and no branch should learn why, not wonder where the button went.
            onPressed: board.canSell ? onNewOrder : null,
          ),
          if (!board.canSell)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                'لا يوجد فرع نشط مُسنَد لك — راجع الإدارة',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.error),
              ),
            ),
          SizedBox(height: 16.h),
        ],
        Text(
          'الطلبات الفورية',
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8.h,
          crossAxisSpacing: 8.w,
          childAspectRatio: 2.4,
          children: [
            for (final key in shownStatuses)
              if (board.statuses.where((s) => s.status == key).firstOrNull case final status?)
                _CountCard(
                  label: status.label,
                  count: status.count,
                  icon: _iconFor(status.status),
                  onTap: () => onOpenStatus(status),
                ),
          ],
        ),
        if (board.lateCount > 0) ...[
          SizedBox(height: 8.h),
          _CountCard(
            label: 'متأخرة (أكثر من ${board.lateAfterHours} ساعة)',
            count: board.lateCount,
            icon: AppIcons.elapsed,
            isWarning: true,
            onTap: onOpenLate,
          ),
        ],
      ],
    );
  }

  static IconData _iconFor(String status) => switch (status) {
    'new' => AppIcons.statusNew,
    'delivered' => AppIcons.ordersReceived,
    _ => AppIcons.orders,
  };
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
    this.isWarning = false,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: isWarning ? scheme.errorContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(icon, size: 20.sp, color: isWarning ? scheme.onErrorContainer : scheme.primary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              Text(
                '$count',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
