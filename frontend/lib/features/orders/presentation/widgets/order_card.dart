import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/theme/app_tones.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/presentation/widgets/order_status_chip.dart';

/// One order in the list.
///
/// A labelled grid, two rows of three: what the order is worth and where it stands read as a
/// pair of facts, not a headline, because the status chip above already says the one thing a
/// work queue is scanned for first. The six cells below answer the questions that follow in the
/// order they get asked — «لمن» ثم «بكام» ثم «فين» — rather than four lines stacked by category.
///
/// **والمال في سطر ثالث خاص به، تحت خط فاصل.** «سعر الطلبية» كان وحده هنا لأن الباك اند لم يكن
/// يعرف كم قُبض؛ صار يعرف، فالسؤال الذي تُفتح البطاقة لأجله — «كم بقي له علينا» — يُجاب في
/// نظرة بدل فتح الطلبية. والثلاثة معاً لا متفرقة: رقمٌ مدفوع بلا الإجمالي بجانبه لا يعني شيئاً.
///
/// **وحالة الدفع شارة بجانب حالة التنفيذ**، لا مدموجة فيها: طلبية «جاهزة» قد تكون مدفوعة أو لا،
/// وهما محوران يتقاطعان — وهو نفس سبب بقائهما enumين منفصلين في الخادم.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, this.onTap, super.key});

  final Order order;
  final VoidCallback? onTap;

  /// Whether the whole card should read as settled.
  ///
  /// The empty label is the guard, not decoration: `paymentStatus` falls back to a value even
  /// for an order from a build of the API that predates payments, and washing such a card green
  /// would be this app claiming something nobody computed.
  bool get _isSettled =>
      order.paymentStatus == PaymentStatus.paid && order.paymentStatusLabel.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      // **A wash, not the fill.** `paidContainer` is the pale green the chips use, and a whole
      // card in it would shout down the status chip and the money below. Held back to about a
      // third over the ordinary surface, «مدفوعة بالكامل» is a row you can pick out of a queue
      // at arm's length without any word on it being read — which is the thing this colour was
      // introduced for — and the card is still a white card with the numbers on it.
      color: _isSettled
          ? Color.alphaBlend(
              scheme.paidContainer.withValues(alpha: 0.35),
              scheme.surfaceContainerLowest,
            )
          : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          // Same border-plus-shadow finish as CustomerCard and ProductCard: a card against this
          // background reads as its own surface only once it has an edge, not just a colour.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              // The edge follows the fill, so a settled card is one decision rather than a green
              // panel inside a grey outline.
              color: _isSettled
                  ? scheme.paid.withValues(alpha: 0.35)
                  : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OrderStatusChip(status: order.status, label: order.statusLabel, compact: true),
                  SizedBox(width: 8.w),
                  // The server's own Arabic, so a payment state added later reads correctly on
                  // a phone that was never updated.
                  _PaymentChip(status: order.paymentStatus, label: order.paymentStatusLabel),
                ],
              ),
              SizedBox(height: 12.h),
              Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Cell(
                      label: 'كود العميل',
                      value: order.customer?.code ?? '#${order.customerId}',
                      isLtr: true,
                    ),
                  ),
                  Expanded(
                    child: _Cell(label: 'رقم الفاتورة', value: '#${order.code}'),
                  ),
                  Expanded(
                    child: _Cell(
                      label: 'رقم الاستلام',
                      value: order.recipientPhone ?? order.customer?.phone ?? '—',
                      isLtr: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Cell(
                      label: 'مكان الاستلام',
                      value: order.isOfficePickup ? order.cityName : order.destination,
                    ),
                  ),
                  Expanded(
                    child: _Cell(label: 'تاريخ الإنشاء', value: order.placedAgo),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
              SizedBox(height: 12.h),
              // The money, as one block. Every figure is the string the server sent — including
              // the subtraction: a total assembled on the server and re-derived on the phone is
              // two answers to one question, and the phone's is the one made of doubles.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Cell(label: 'سعر الطلبية', value: order.grandTotal, emphasize: true),
                  ),
                  Expanded(
                    child: _Cell(label: 'المدفوع', value: order.paidAmount),
                  ),
                  Expanded(
                    child: _Cell(
                      label: 'المتبقي',
                      value: order.remainingAmount,
                      // The one thing a work queue is scanned for after the status. Coloured
                      // only when something is still owed — a zero in alarm red would make the
                      // settled case look like the problem.
                      tone: order.isOutstanding ? scheme.error : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One labelled fact — the label above, muted and small; the value below it.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    this.isLtr = false,
    this.emphasize = false,
    this.tone,
  });

  final String label;
  final String value;

  /// A phone number or a customer code — read left-to-right even inside this RTL card.
  final bool isLtr;

  /// The order's price: the one number on the card worth the primary colour.
  final bool emphasize;

  /// Overrides the colour outright — «المتبقي» in the error tone while anything is owed. Wins
  /// over [emphasize], because a cell is never both.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          textAlign: TextAlign.center,
          textDirection: isLtr ? TextDirection.ltr : null,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: tone ?? (emphasize ? scheme.primary : scheme.onSurface),
          ),
        ),
      ],
    );
  }
}

/// Where the order stands on its money, as a chip beside the status one.
///
/// **Its own shape, not a second status chip.** The two sit on one line and answer different
/// questions, so this one is deliberately quieter — an outline rather than a fill — and only
/// takes a colour when the answer is worth acting on.
class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.status, required this.label});

  final PaymentStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // Nothing sent — an order from a build of the API that predates payments. Silence beats a
    // chip reading «غير مدفوعة» about a number nobody computed.
    if (label.isEmpty) return const SizedBox.shrink();

    final tone = switch (status) {
      // Green, not `primary`: the teal is the price directly beneath this chip and half the app
      // besides, and «مدفوعة بالكامل» is the one state worth reading without reading the word.
      PaymentStatus.paid => scheme.paid,
      PaymentStatus.overpaid => scheme.tertiary,
      PaymentStatus.unpaid => scheme.error,
      PaymentStatus.partiallyPaid || PaymentStatus.unknown => scheme.onSurfaceVariant,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodySmall?.copyWith(color: tone, fontWeight: FontWeight.w700),
      ),
    );
  }
}
