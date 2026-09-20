import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_pools/models/investment_pool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One row of the pools list: the material, the shelves it buys, and who is in it.
///
/// **No status pill.** A صفقة had one because a صفقة ends; a صندوق never closes, so a word saying
/// «مفتوح» on every row for ever would be a column of noise. What changes here is the period, and
/// that belongs on the pool's own screen where the dates can be read.
class PoolCard extends StatelessWidget {
  const PoolCard({required this.pool, required this.onTap, super.key});

  final InvestmentPool pool;
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
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pool.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    pool.code,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                _shelves(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _Fact(
                    label: 'الشركاء',
                    value: pool.investors.length.grouped,
                  ),
                  SizedBox(width: 16.w),
                  _Fact(
                    label: 'حصة المستثمرين',
                    value: '${pool.investorProfitSharePercent.grouped}٪',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// «ورق 25×35 · حبر أسود», or the count once naming them would not fit.
  String _shelves() {
    if (pool.stockItems.isEmpty) return 'لا مواد بعد';

    final named = pool.stockItems
        .map((item) => item.name)
        .whereType<String>()
        .toList();

    if (named.isEmpty) {
      return '${pool.stockItems.length.grouped} مادة';
    }

    if (named.length <= 2) return named.join(' · ');

    return '${named.take(2).join(' · ')} +${(named.length - 2).grouped}';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
