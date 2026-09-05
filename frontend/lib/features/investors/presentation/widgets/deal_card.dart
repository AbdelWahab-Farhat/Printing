import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One row of the deals list: what it is called, where it stands, and on what terms.
class DealCard extends StatelessWidget {
  const DealCard({required this.deal, required this.onTap, super.key});

  final InvestorDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);

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
                      deal.code,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      deal.statusLabel,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                '${deal.code} · للمستثمرين ${trimDecimals(deal.investorProfitSharePercent)}%'
                '${deal.investors.isEmpty ? '' : ' · ${deal.investors.length} مستثمر'}',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
