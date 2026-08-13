import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/theme/app_tones.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';

/// One rate: what kind of cost it is, what it applies to, and how much it adds per unit.
///
/// **The rung is the whole row.** Three rates for «عمالة» that differ only in what they are
/// pinned to are three identical lines otherwise, and picking the wrong one to edit is how a
/// workshop-wide default gets quietly rewritten to one product's number. So the rung is said
/// twice — once as the glyph, which is what the eye lands on scanning a column, and once in
/// words underneath.
///
/// A stopped rate keeps its name in full colour and loses only the tint on its glyph: it is
/// still a true record of what the workshop once charged, so greying the row out would misread
/// «لم يعد يُطبَّق» as «خطأ».
class ManufacturingCostRateCard extends StatelessWidget {
  const ManufacturingCostRateCard({
    required this.rate,
    this.onTap,
    this.onToggleActive,
    this.onDelete,
    super.key,
  });

  final ManufacturingCostRate rate;

  /// Opens the form. Null for somebody who may only read the table.
  final VoidCallback? onTap;

  /// Null for a reader, which is what leaves the switch out entirely rather than showing a
  /// control that refuses.
  final ValueChanged<bool>? onToggleActive;

  /// Null for a reader. Deleting is the rare one — retiring a rate is the switch above — so it
  /// sits last, past the control somebody actually came for.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              _Glyph(scope: rate.scope, isActive: rate.isActive),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            // The server's own word for *this* rate, so a kind added later still
                            // reads right.
                            rate.costTypeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _Rate(rate: rate),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _subtitle(rate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (!rate.costType.isRateDriven) ...[
                          SizedBox(width: 6.w),
                          const _NeverAppliedPill(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onToggleActive != null)
                Switch(value: rate.isActive, onChanged: onToggleActive),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(AppIcons.delete, size: 20.sp),
                  color: scheme.error,
                  tooltip: 'حذف المعدل',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the rate applies to, and whether it still does.
///
/// «موقوف» rides on the same line rather than becoming a badge of its own: it is the second
/// thing a reader wants after the rung, and a row that grew a pill for it would push the rung
/// off a narrow phone.
String _subtitle(ManufacturingCostRate rate) =>
    rate.isActive ? rate.scopeLabel : '${rate.scopeLabel} · موقوف';

/// The number the row exists to give.
class _Rate extends StatelessWidget {
  const _Rate({required this.rate});

  final ManufacturingCostRate rate;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          // `'3.500'` reads as a rate to a database and as noise to a foreman.
          rate.rateLabel,
          textDirection: TextDirection.ltr,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        Text(
          'د.ل للوحدة',
          style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// «لا يُطبَّق» — the warning that belongs on a خسارة تلف rate and on nothing else.
///
/// The API accepts such a rate, stores it and lists it, and then never reads it: a scrap loss is
/// priced from the FIFO cost of the stock actually written off. A row that said nothing would be
/// a number somebody believes is being charged.
class _NeverAppliedPill extends StatelessWidget {
  const _NeverAppliedPill();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: scheme.warnContainer,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        'لا يُطبَّق',
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onWarnContainer,
        ),
      ),
    );
  }
}

/// The rung, as a glyph — a whole product, one size, or everything else.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.scope, required this.isActive});

  final RateScope scope;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      height: 38.w,
      width: 38.w,
      decoration: BoxDecoration(
        // The tint is the only thing that changes when a rate is stopped: enough to scan the
        // list by, not enough to make the row read as broken.
        color: isActive ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        switch (scope) {
          RateScope.variant => AppIcons.tag,
          RateScope.product => AppIcons.products,
          RateScope.standard => AppIcons.payment,
        },
        size: 19.sp,
        color: isActive ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
      ),
    );
  }
}
