import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One of his deals: what he has in it, what it has earned him, and where it stands.
///
/// No quantities, no unit costs, and nobody else's share — what he financed and what it made him
/// is the whole of his business with us.
class InvestorDealCard extends StatelessWidget {
  const InvestorDealCard({required this.deal, super.key});

  final InvestorDealLine deal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isLoss = deal.profit.startsWith('-');

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
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
                  deal.code ?? 'صفقة',
                  style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (deal.statusLabel != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    deal.statusLabel!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '${deal.code ?? ''} · حصتي ${trimDecimals(deal.sharePercent)}%',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _Figure(label: 'رأس مالي', amount: deal.capital, colour: scheme.onSurface),
              ),
              Expanded(
                child: _Figure(
                  label: isLoss ? 'خسارتي' : 'ربحي',
                  // The label carries the sign, so the figure must not carry it too.
                  amount: unsigned(deal.profit),
                  colour: isLoss ? scheme.error : scheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        // Forced left-to-right inside the right-to-left tree: a grouped number laid out
        // right-to-left lands its separator on the wrong side of the digits.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            maxLines: 1,
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colour,
            ),
          ),
        ),
      ],
    );
  }
}
