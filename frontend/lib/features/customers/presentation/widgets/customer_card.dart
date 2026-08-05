import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/customers/models/customer.dart';

/// One customer in the list.
///
/// Name, code and phone — the three things a customer is looked up by, so all three are on the
/// card rather than one screen deeper.
///
/// **A square holds the code, not an initial.** It used to show the first letter of the name,
/// and on a list of Libyan print shops that is «م» on almost every row: the eye met the same
/// glyph each time and learned to skip the column. That is the exact failure `ProductCard`
/// records for the placeholder thumbnail it removed for the same reason. The code is the one
/// thing on the row that is unique, short, and said out loud on the phone — so it gets a square
/// of its own, and the faint grey chip that used to carry it is gone rather than duplicated.
///
/// **The square sits at the far left, so it lands last in Arabic reading order.** The name is
/// what a row is found by and it keeps the start of the line; the code is what the row is then
/// *quoted* by, and a column of codes down one edge is a column to run a finger along. Being
/// the last child of an RTL row is what puts it there — not an alignment, so it cannot drift
/// when the name grows.
class CustomerCard extends StatelessWidget {
  const CustomerCard({required this.customer, this.onTap, super.key});

  final Customer customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        // Only when it is *not* the normal case: a badge on every row stops
                        // being read.
                        if (!customer.isActive) const _InactiveBadge(),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(AppIcons.phone, size: 15.sp, color: scheme.onSurfaceVariant),
                        SizedBox(width: 5.w),
                        Text(
                          customer.phone,
                          // A Libyan number reads left-to-right even inside this RTL card.
                          textDirection: TextDirection.ltr,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              // Last child of an RTL row, so it lands on the far left — a column of codes down
              // one edge, in the place Arabic reading order arrives at rather than starts from.
              _CodeBadge(code: customer.code, isActive: customer.isActive),
            ],
          ),
        ),
      ),
    );
  }
}

/// The customer's code, in the card's most prominent slot.
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code, required this.isActive});

  final String code;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      height: 48.w,
      width: 48.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        // The square keeps saying whether the customer is switched off, which is the one thing
        // it was already carrying that was worth carrying.
        color: isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14.r),
      ),
      // Codes are 'C' + the row id, so they grow: C9 today, C1284 in two years. Scaled down to
      // fit rather than clipped — half a code is worse than a small one, because «C12…» and
      // «C128…» read as the same customer.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          code,
          // A Latin letter and digits: they read left-to-right even inside this RTL card.
          textDirection: TextDirection.ltr,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _InactiveBadge extends StatelessWidget {
  const _InactiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        'موقوف',
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
