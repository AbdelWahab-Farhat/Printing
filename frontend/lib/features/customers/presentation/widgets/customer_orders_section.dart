import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/counted_entry_row.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_order_counts_cubit.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/orders_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «إدارة الطلبات» — four ways into one customer's orders.
///
/// **The only way to a customer's orders that does not go through a search box.** Until this
/// existed, answering «ماذا طلب هذا العميل؟» meant leaving their screen for the orders tab and
/// typing their code into a list that is about everybody — a question asked on one screen and
/// answered on another.
///
/// Each row builds its own [OrdersFilter] and hands it up. The statuses come from
/// [OrderStatus.inProgress], `.received` and `.cancellations`, which are the same groups the
/// numbers beside them were added up from — so a row cannot open something that disagrees with
/// its own count. See CUSTOMER-ORDERS-SECTION.md.
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

  /// The four numbers, or the reason there are none. **Never blocks a tap** — see
  /// [CountedEntryRow].
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
        CountedEntryRow(
          icon: AppIcons.orders,
          tone: CountedEntryTone.primary,
          title: 'كل طلبات العميل',
          subtitle: 'عرض جميع الطلبات',
          count: loaded?.total,
          // No statuses at all: «كل» means every one of them, written-off orders included. A
          // total that quietly dropped the cancellations would disagree with the number above it.
          onTap: () => onOpen(
            OrdersFilter(
              title: 'كل الطلبات · $customerName',
              customerId: customerId,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        CountedEntryRow(
          icon: AppIcons.ordersInProgress,
          tone: CountedEntryTone.tertiary,
          title: 'الطلبات الجارية',
          subtitle: 'الطلبات قيد التنفيذ',
          count: loaded?.inProgress,
          onTap: () => onOpen(
            OrdersFilter(
              title: 'الطلبات الجارية · $customerName',
              statuses: OrderStatus.inProgress
                  .map((status) => status.wire)
                  .toList(),
              customerId: customerId,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        CountedEntryRow(
          icon: AppIcons.ordersReceived,
          tone: CountedEntryTone.secondary,
          title: 'الطلبات المستلمة',
          subtitle: 'الطلبات التي وصلت العميل',
          count: loaded?.received,
          onTap: () => onOpen(
            OrdersFilter(
              title: 'الطلبات المستلمة · $customerName',
              statuses: OrderStatus.received
                  .map((status) => status.wire)
                  .toList(),
              customerId: customerId,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        // **Its own row rather than something to be dug out of «الكل».** «كم طلبية ألغينا لهذا
        // العميل؟» is asked directly, and an answer that requires opening a list of everything
        // and filtering it by eye is not an answer this screen gave.
        CountedEntryRow(
          icon: AppIcons.ordersCancelled,
          tone: CountedEntryTone.muted,
          title: 'الطلبات الملغاة',
          subtitle: 'الطلبات التي أُلغيت',
          count: loaded?.cancelled,
          onTap: () => onOpen(
            OrdersFilter(
              title: 'الطلبات الملغاة · $customerName',
              statuses: OrderStatus.cancellations
                  .map((status) => status.wire)
                  .toList(),
              customerId: customerId,
            ),
          ),
        ),
      ],
    );
  }
}
