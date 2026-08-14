import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
                        // How much business this customer does, beside how to reach them —
                        // which is the pair somebody scanning this list is weighing. Absent
                        // when the server sent no count: see `Customer.ordersCount`.
                        // Flexible, and the phone is not: at a large system text scale something
                        // on this line has to give, and it must not be the number somebody rings.
                        //
                        // **The silence replaces the count rather than joining it**, on the one
                        // list that has a date to show — «الأقدم طلباً». The row is read for the
                        // number it was sorted by, and both on this line would be a line too
                        // long on a phone. A customer on that same list who has never ordered
                        // has no date, so the count falls through and says «لا طلبيات» — which
                        // is the answer that sort gives about them anyway.
                        if (customer.lastOrderAgo case final silence?) ...[
                          SizedBox(width: 10.w),
                          Flexible(child: _LastOrderBadge(label: silence)),
                        ] else if (customer.ordersCount case final orders?) ...[
                          SizedBox(width: 10.w),
                          Flexible(child: _OrdersBadge(count: orders)),
                        ],
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

/// How many orders this customer has placed, ever.
///
/// **Zero says so in words rather than going quiet.** A row that shows nothing at zero teaches
/// the eye that the slot is noise, and then «١٧ طلبية» on the row below it does not get read
/// either. «لا طلبيات» is also the one thing on this card that answers «هل هذا عميل جديد؟»
/// without opening him.
class _OrdersBadge extends StatelessWidget {
  const _OrdersBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isNew = count == 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          AppIcons.orders,
          size: 15.sp,
          color: isNew ? scheme.outline : scheme.onSurfaceVariant,
        ),
        SizedBox(width: 5.w),
        Flexible(
          child: Text(
            // Not «٠ طلبية»: a numeral standing for nothing is read as a number before it is
            // read as an absence, and Arabic has a shorter way to say it.
            isNew ? 'لا طلبيات' : '${count.grouped} طلبية',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              color: isNew ? scheme.outline : scheme.onSurfaceVariant,
              fontWeight: isNew ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// How long it has been since this customer last ordered — «منذ شهرين».
///
/// **Its own glyph, not the orders one.** It stands where the count stands and is read in the
/// same glance, so borrowing that icon would make «منذ شهرين» look like a quantity of orders.
/// A clock is what the row is actually about on this list: elapsed time.
class _LastOrderBadge extends StatelessWidget {
  const _LastOrderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.elapsed, size: 15.sp, color: scheme.onSurfaceVariant),
        SizedBox(width: 5.w),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
