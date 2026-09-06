import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investors/models/order_investor_share.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/order_investor_shares_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Who took money out of this order, how much, and whether they have actually taken it.
///
/// **A section of its own, under «التكلفة والربح» and never inside it**, and the reason is
/// arithmetic rather than layout. A `plain_sale` row is what the press *paid* an investor for
/// plain bags when they left the shelf: that money is inside `material_cost`, which is inside
/// «تكلفة الإنتاج», which is *above* «مجمل الربح». Printed as a line under the profit it would
/// read as a share of it — and it is the opposite, a cost that produced it. An `order_profit`
/// row genuinely is carved out of that profit. One column cannot say both, so each row says
/// which it is and the two are never subtotalled.
///
/// **Draws nothing at all when the order touched no deal**, which is most orders: an empty card
/// under a heading would put a question on the screen — «وأين المستثمرون إذن؟» — that the
/// absence of the section already answers.
class OrderInvestorsSection extends StatelessWidget {
  const OrderInvestorsSection({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderInvestorSharesCubit>(
      create: (_) => sl<OrderInvestorSharesCubit>()..load(orderId),
      child: BlocBuilder<OrderInvestorSharesCubit, OrderInvestorSharesState>(
        builder: (context, state) => switch (state) {
          // Silent while it loads and silent when it fails. This is a side answer from another
          // module about an order that renders perfectly without it; a spinner or an error strip
          // here would interrupt the screen for something nobody opened it to read.
          OrderInvestorSharesLoading() => const SizedBox.shrink(),
          OrderInvestorSharesFailure() => const SizedBox.shrink(),
          OrderInvestorSharesLoaded(:final shares) => shares.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final share in shares) _ShareCard(share: share),
                  ],
                ),
        },
      ),
    );
  }
}

/// One deal's row: the road it came by, the money, and whether it has been paid.
class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.share});

  final OrderInvestorShare share;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${share.dealCode} · ${share.kindLabel}',
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // **The answer to «هل أخذ منها المستثمر مالاً أو لا», said as a word rather than
                // left to be inferred from a figure.** Unpaid is not an error and is not
                // coloured like one: it is the ordinary state of a deal still riding a sale.
                Text(
                  share.isPaid ? 'مدفوع' : 'لم يُدفع بعد',
                  style: text.bodyMedium?.copyWith(
                    color: share.isPaid ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _Line(
              label: 'للمستثمرين',
              value: share.isPaid ? share.paidAmount : share.investorsShare,
              isTotal: true,
            ),
            _Line(label: 'للشركة', value: share.companyShare),
            SizedBox(height: 6.h),
            Text(
              _explanation(share),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  /// Where the figure above came from, in one sentence — the two roads read differently enough
  /// that a person seeing only the amounts would work out the wrong story.
  String _explanation(OrderInvestorShare share) {
    if (share.isPlainSale) {
      return 'اشترت المطبعة السادة بـ ${groupedDecimal(share.goodsAmount ?? '0')} د.ل '
          '· ربح ${groupedDecimal(share.profit)} د.ل · عند خروج البضاعة من المخزن';
    }

    return 'نصيب الصفقة من ربح الطلبية ${groupedDecimal(share.profit)} د.ل '
        '· يُدفع عند «تم الاستلام»';
  }
}

/// One figure on the card, drawn the way «التكلفة والربح» draws its own.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.isTotal = false});

  final String label;
  final String? value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final style = isTotal
        ? text.bodyLarge?.copyWith(fontWeight: FontWeight.w800)
        : text.bodyLarge;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyLarge)),
          Text('${groupedDecimal(value ?? '0')} د.ل', style: style),
        ],
      ),
    );
  }
}
