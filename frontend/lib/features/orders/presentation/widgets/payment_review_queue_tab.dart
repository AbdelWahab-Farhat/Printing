import 'dart:async';

import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_review_queue_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_queue_filters.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_review_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تبويب «تحتاج مراجعة» في «مراجعة وتسوية الدفعات» — كل دفعةٍ وردٍّ ينتظر أن يراجعه شخص، الأقدم
/// أولاً. (كان تبويباً في «المالية» حتى ٢٠٢٦-١٠-٠٨.)
///
/// **فوق الصفوف رأسُ الصفحة المشترك** ([PaymentQueueFilters]) ويمرّ معها: البحث، وأزرار الفترة على
/// «الكل»، والفلتر المتقدّم بـ«من» / «إلى» والنوع. والعدد في اسم التبويب، لا في سطرٍ تحت الفلاتر.
///
/// **لا يوقف شيئاً**: دفعةٌ غير مراجَعة تُحسب وتُسوّى وتحرّك الخزينة كالمراجَعة تماماً؛ هذه قائمة
/// عمل المراجع لا بوّابة. واللمسة على الصفّ تفتح دفعات طلبيته، حيث يُرى الواصل والسجلّ كلّه.
class PaymentReviewQueueTab extends StatelessWidget {
  const PaymentReviewQueueTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentReviewQueueCubit>();

    return BlocBuilder<PaymentReviewQueueCubit, PaymentReviewQueueState>(
      builder: (context, state) => PagedListView<OrderPayment>(
        state: state,
        header: PaymentQueueFilters(
          period: cubit.period,
          onPeriod: (period) => unawaited(cubit.showPeriod(period)),
          onSearch: cubit.search,
          isAdvancedActive: cubit.hasAdvanced,
          onAdvanced: () => unawaited(_advanced(context)),
        ),
        emptyMessage: 'لا دفعات تحتاج مراجعة',
        onLoadMore: cubit.loadMore,
        onRefresh: cubit.refresh,
        skeletonHeight: 96.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, payment, index) => _Row(
          key: ValueKey(payment.id),
          payment: payment,
          onOpen: () => unawaited(_open(context, payment)),
          onReview: () => unawaited(_review(context, payment)),
        ),
      ),
    );
  }

  /// «من» / «إلى» and payments or refunds.
  Future<void> _advanced(BuildContext context) async {
    final cubit = context.read<PaymentReviewQueueCubit>();
    final range = cubit.customRange;
    final chosen = await showPaymentAdvancedFilter(
      context: context,
      current: PaymentAdvancedFilter(from: range?.from, to: range?.to, type: cubit.type),
      offersType: true,
    );

    if (chosen == null) return;

    await cubit.applyAdvanced(from: chosen.from, to: chosen.to, type: chosen.type);
  }

  /// The order's own ledger, where the receipt and every other entry are. Re-read on the way
  /// back only when something was written there — a review made on that screen included.
  Future<void> _open(BuildContext context, OrderPayment payment) async {
    final cubit = context.read<PaymentReviewQueueCubit>();

    await context.pushForResult<bool>(
      Routes.orderPayments(payment.orderId),
      extra: payment.order?.code ?? '',
    );

    if (context.mounted) unawaited(cubit.refresh());
  }

  Future<void> _review(BuildContext context, OrderPayment payment) async {
    final failure = await context.read<PaymentReviewQueueCubit>().review(payment);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess('تمت مراجعة الدفعة');
  }
}

/// One entry waiting: which order, how much and which way, how and when, and who took it.
class _Row extends StatelessWidget {
  const _Row({
    required this.payment,
    required this.onOpen,
    required this.onReview,
    super.key,
  });

  final OrderPayment payment;
  final VoidCallback onOpen;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = payment.isIncoming ? scheme.primary : scheme.error;
    final order = payment.order;

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(payment.isIncoming ? AppIcons.payment : AppIcons.refund, size: 18.sp, color: tone),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          payment.typeLabel,
                          if (order != null) '#${order.code}',
                          if (order?.customerName case final name? when name.isNotEmpty) name,
                        ].join(' · '),
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        [
                          if (payment.methodLabel case final label? when label.isNotEmpty) label,
                          if (payment.reference case final reference? when reference.isNotEmpty)
                            reference,
                          if (payment.paidAt case final paidAt?) paidAt.dayLabel,
                          if (payment.recordedBy case final recorder?) recorder.name,
                        ].join(' · '),
                        style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${payment.isIncoming ? '+' : '−'} ${payment.amount.grouped}',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 28.w, top: 4.h),
              child: PaymentReviewLine(
                payment: payment,
                isBusy: false,
                // The queue only ever marks: a row it holds has no review to take back.
                onReview: (reviewed) {
                  if (reviewed) onReview();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
