import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/theme/app_tones.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/core/widgets/appear.dart';
import 'package:printing/features/home/models/home_summary.dart';
import 'package:printing/features/orders/models/order_payment.dart';

/// Where the money stands, one card per payment state.
///
/// **A second board rather than three more cards on the status one**, because the two axes
/// cross: an order can be finished and unpaid, or paid before it is printed. «كم طلبية لم تُدفع»
/// is unanswerable from the statuses above it, which is the whole reason the server sends this
/// as its own list.
///
/// **Three cards, not four.** «مدفوعة بالزيادة» arises only from a discount granted after
/// payment; it is a rarity to notice on an order, not a queue anybody works through in the
/// morning — see [PaymentStatus.filterable]. An overpaid order still says so on its own card.
///
/// Rendered from the list the server sent, in its order, so a state added to the business
/// appears here without an app release. The Arabic travels with the number for the same reason.
class PaymentBoard extends StatelessWidget {
  const PaymentBoard({required this.payments, this.onOpen, super.key});

  final List<OrderStatusCount> payments;

  /// Opens the orders behind one card. Null leaves the board readable and inert.
  final ValueChanged<OrderStatusCount>? onOpen;

  /// Only the states somebody works a queue of, in the order the filter offers them.
  List<OrderStatusCount> get _cards {
    final wanted = PaymentStatus.filterable.map((status) => status.wire).toList();

    return [for (final wire in wanted) ...payments.where((payment) => payment.status == wire)];
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 4.w, bottom: 12.h),
          child: Text(
            'حالات الدفع',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
        Row(
          children: [
            for (final (index, payment) in cards.indexed) ...[
              if (index > 0) SizedBox(width: 10.w),
              Expanded(
                child: Appear(
                  index: index,
                  child: _PaymentCard(
                    payment: payment,
                    // A card counting nothing opens a screen saying so, which is a tap that
                    // teaches the reader nothing they did not already see.
                    onTap: onOpen == null || payment.count == 0 ? null : () => onOpen!(payment),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, this.onTap});

  final OrderStatusCount payment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **Two of the three are coloured, and only while they count something.** The board above
    // learned this the hard way: a mark that appears while counting zero is a claim about
    // nothing, and it teaches the reader to stop believing the mark.
    //
    // Red for the debt and green for the settled — «مدفوعة جزئياً» keeps the plain ink, because
    // it is the state in between and colouring all three would leave nothing standing out.
    final counts = payment.count > 0;
    final tone = switch (payment.status) {
      _ when !counts => scheme.onSurface,
      final status when status == PaymentStatus.unpaid.wire => scheme.error,
      final status when status == PaymentStatus.paid.wire => scheme.paid,
      _ => scheme.onSurface,
    };

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              Icon(AppIcons.payment, size: 20.sp, color: tone.withValues(alpha: 0.8)),
              SizedBox(height: 8.h),
              Text(
                payment.count.grouped,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tone,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                // The server's own Arabic — this app holds no translation table, and the title
                // of the screen the card opens can only come from the card that opened it.
                payment.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
