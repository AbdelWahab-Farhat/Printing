import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_order_counts_cubit.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/models/orders_filter.dart';

/// «إدارة الطلبات» — three ways into one customer's orders.
///
/// **The only way to a customer's orders that does not go through a search box.** Until this
/// existed, answering «ماذا طلب هذا العميل؟» meant leaving their screen for the orders tab and
/// typing their code into a list that is about everybody — a question asked on one screen and
/// answered on another.
///
/// Each row builds its own [OrdersFilter] and hands it up. The statuses come from
/// [OrderStatus.inProgress] and [OrderStatus.received], which are the same groups the numbers
/// beside them were added up from — so a row cannot open something that disagrees with its own
/// count. See CUSTOMER-ORDERS-SECTION.md.
class CustomerOrdersSection extends StatelessWidget {
  const CustomerOrdersSection({
    required this.customerId,
    required this.customerName,
    required this.state,
    required this.onOpen,
    super.key,
  });

  final int customerId;

  /// Travels into the title of the screen each row opens: that screen is handed an id, not a
  /// person, so this is its only way to say whose orders it is showing.
  final String customerName;

  /// The three numbers, or the reason there are none. **Never blocks a tap** — see [_Row].
  final CustomerOrderCountsState state;

  final ValueChanged<OrdersFilter> onOpen;

  @override
  Widget build(BuildContext context) {
    final loaded = state is CustomerOrderCountsLoaded
        ? state as CustomerOrderCountsLoaded
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إدارة الطلبات',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.colorScheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        _Row(
          icon: AppIcons.orders,
          tint: _Tint.primary,
          title: 'كل طلبات العميل',
          subtitle: 'عرض جميع الطلبات',
          count: loaded?.total,
          // No statuses at all: «كل» means every one of them, written-off orders included. A
          // total that quietly dropped the cancellations would disagree with the number above it.
          onTap: () => onOpen(
            OrdersFilter(title: 'كل الطلبات · $customerName', customerId: customerId),
          ),
        ),
        SizedBox(height: 10.h),
        _Row(
          icon: AppIcons.ordersInProgress,
          tint: _Tint.tertiary,
          title: 'الطلبات الجارية',
          subtitle: 'الطلبات قيد التنفيذ',
          count: loaded?.inProgress,
          onTap: () => onOpen(
            OrdersFilter(
              title: 'الطلبات الجارية · $customerName',
              statuses: OrderStatus.inProgress.map((status) => status.wire).toList(),
              customerId: customerId,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        _Row(
          icon: AppIcons.ordersReceived,
          tint: _Tint.secondary,
          title: 'الطلبات المستلمة',
          subtitle: 'الطلبات التي وصلت العميل',
          count: loaded?.received,
          onTap: () => onOpen(
            OrdersFilter(
              title: 'الطلبات المستلمة · $customerName',
              statuses: OrderStatus.received.map((status) => status.wire).toList(),
              customerId: customerId,
            ),
          ),
        ),
      ],
    );
  }
}

/// Which of the scheme's container pairs the icon tile is drawn from.
///
/// Three families rather than three tints of one, so the rows are told apart by shape *and*
/// colour at a glance — and drawn from the scheme rather than from constants, so both themes
/// get them right without this file knowing which one it is in.
enum _Tint { primary, tertiary, secondary }

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final _Tint tint;
  final String title;
  final String subtitle;

  /// Null while the counts are in flight or after they failed. **The row still opens.** Reaching
  /// a customer's orders must not depend on having counted them first, and «٠» in the place of a
  /// number nobody managed to read is the one thing here that would be a lie.
  final int? count;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(16.r);

    final (background, foreground) = switch (tint) {
      _Tint.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Tint.tertiary => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _Tint.secondary => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Container(
                height: 44.w,
                width: 44.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 22.sp, color: foreground),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Absent rather than a placeholder while the number is unknown: a dash or a
              // spinner in a numeral's slot is read as a value.
              if (count case final total?) ...[
                SizedBox(width: 8.w),
                Text(
                  total.grouped,
                  // Digits read left-to-right even inside this RTL row.
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
              SizedBox(width: 4.w),
              Icon(AppIcons.forward, size: 20.sp, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
