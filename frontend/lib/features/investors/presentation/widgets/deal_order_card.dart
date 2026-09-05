import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investors/models/deal_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One row of «طلبيات الصفقة»: which order, what it took, and what it earned.
///
/// Built the way [_Participant] on the deal screen is, and for the same reason — the two figures
/// are the biggest things on the row, because the order code above them is not what a person
/// opened this list to read.
///
/// **The investors' share is drawn only once it exists.** Before «تم الاستلام» nothing has been
/// paid, and a 0.00 there would say the order broke even rather than that it is still on the
/// road — which the status pill already says.
class DealOrderCard extends StatelessWidget {
  const DealOrderCard({required this.order, this.onTap, super.key});

  final DealOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);

    final isLoss = order.profit.startsWith('-');

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'طلبية ${order.code}',
                      style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Figure(
                      // The label carries the sign, so the number never shows a minus twice.
                      label: isLoss ? 'خسارة الصفقة' : 'ربح الصفقة',
                      amount: unsigned(order.profit),
                      colour: isLoss ? scheme.error : scheme.primary,
                    ),
                  ),
                  Expanded(
                    child: order.investorsShare == null
                        ? const SizedBox.shrink()
                        : _Figure(
                            label: order.investorsShare!.startsWith('-')
                                ? 'خسارة المستثمرين'
                                : 'نصيب المستثمرين',
                            amount: unsigned(order.investorsShare!),
                            colour: scheme.onSurface,
                          ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                _drawn,
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (_who != null)
                Text(
                  _who!,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// What came off this deal's shelves and what it had cost it — the two figures the profit
  /// above was worked out from.
  String get _drawn =>
      '${groupedDecimal(order.quantity)} وحدة · تكلفتها ${order.materialCost.grouped} د.ل';

  /// Who bought it and when, when either is known.
  String? get _who {
    final parts = <String>[
      if (order.customerName != null && order.customerName!.isNotEmpty) order.customerName!,
      if (order.occurredAt != null) order.occurredAt!.dayLabel,
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// A labelled figure: the caption quiet, the money big — the deal screen's own.
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.amount, required this.colour});

  final String label;
  final String amount;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            maxLines: 1,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colour,
            ),
          ),
        ),
      ],
    );
  }
}
