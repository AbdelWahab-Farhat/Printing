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
/// **Built to the shape the reference app uses**, because that is the shape the people running
/// this business already read a customer in: one line along the top saying *who* this is, and
/// beneath it a wide, quiet band of labelled fields saying what you do about them. Nothing on
/// the card is packed against anything else — the air is the layout, not decoration on top of
/// it, which is why the vertical gaps here are large enough to look like mistakes and are not.
///
/// **The strip carries the identity, the fields carry the facts.** A row of icon-plus-value
/// makes the reader learn what each glyph stands for; a label over its value does not. So the
/// phone lost its handset and gained «رقم الهاتف», and the orders count lost its document glyph
/// and gained a heading that changes with what the column is actually showing.
///
/// **The code sits at the far left of the strip, so it lands last in Arabic reading order.**
/// The name is what a row is found by and it keeps the start of the line; the code is what the
/// row is then *quoted* by, and a column of codes down one edge is a column to run a finger
/// along. Being the last child of an RTL row is what puts it there — not an alignment, so it
/// cannot drift when the name grows.
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
          // Deep at the bottom, shallow at the top: the strip is the card's own lid and sits
          // close under the edge, while the fields are given the room the reference gives them.
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 60.h),
          decoration: BoxDecoration(
            // The same white the warehouse rows are, and it has to be painted *here* rather
            // than left to the Material below. A `BoxShadow` is drawn as the whole rounded
            // rectangle filled and blurred, so with no colour on this decoration the shadow
            // washed straight across the card's face and turned it grey — a 5% black veil over
            // every customer. `BoxDecoration` paints shadows first and the colour over them,
            // which is what puts the shadow back outside the edge where it belongs.
            color: scheme.surfaceContainerLowest,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _IdentityStrip(customer: customer),
              SizedBox(height: 52.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Field(
                      label: 'رقم الهاتف',
                      value: customer.phone,
                      // A Libyan number reads left-to-right even inside this RTL card.
                      valueDirection: TextDirection.ltr,
                    ),
                  ),
                  Expanded(child: _OrdersField(customer: customer)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Who this row is about: the glyph, the name, and the code it is quoted by.
///
/// **No fill behind it.** It was a tinted band, and a grey slab across the top of a white card
/// reads as a row that has been switched off — every customer on the list looked deactivated.
/// The person glyph is already the fixed place the eye lands on, and it costs nothing.
class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Icon(AppIcons.person, size: 20.sp, color: scheme.onSurfaceVariant),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            customer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // Full-strength ink, now that there is no tint under it to lift it off the card.
            // The name is what the row is found by; muted, it read as switched off.
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        // Only when it is *not* the normal case: a badge on every row stops being read.
        if (!customer.isActive) ...[SizedBox(width: 8.w), const _InactiveBadge()],
        SizedBox(width: 10.w),
        Text(
          '#',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.outline,
          ),
        ),
        SizedBox(width: 6.w),
        _Code(code: customer.code, isActive: customer.isActive),
      ],
    );
  }
}

/// The customer's code — `C8`, `C1284` — at the far left of the strip.
class _Code extends StatelessWidget {
  const _Code({required this.code, required this.isActive});

  final String code;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ConstrainedBox(
      // Codes are 'C' + the row id, so they grow: C9 today, C1284 in two years. Capped and
      // scaled down to fit rather than clipped — half a code is worse than a small one, because
      // «C12…» and «C128…» read as the same customer. The cap is what stops a long one from
      // eating the name beside it.
      constraints: BoxConstraints(maxWidth: 110.w),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          code,
          // A Latin letter and digits: they read left-to-right even inside this RTL card.
          textDirection: TextDirection.ltr,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            // The code keeps saying whether the customer is switched off, which is the one thing
            // the old square was carrying that was worth carrying.
            color: isActive ? scheme.onSurfaceVariant : scheme.outline,
          ),
        ),
      ),
    );
  }
}

/// A heading with its value under it, centred in its half of the row.
///
/// Centred because the pair is read as one block against the identical block beside it, and two
/// centred blocks are what makes the card's lower half look deliberate rather than left over.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.valueDirection});

  final String label;
  final String value;
  final TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          value,
          textAlign: TextAlign.center,
          textDirection: valueDirection,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The second column: how much business this customer does.
///
/// **The heading changes with the answer.** On «الأقدم طلباً» the list is sorted by the silence
/// and the row is read for it, so the column says «آخر طلبية» and shows «منذ شهرين»; putting
/// that under «الطلبيات» would read as a quantity of orders. Everywhere else the column is the
/// count.
///
/// **Zero says so in words rather than going quiet.** A row that shows nothing at zero teaches
/// the eye that the slot is noise, and then «١٧ طلبية» on the row below it does not get read
/// either. «لا طلبيات» is also the one thing on this card that answers «هل هذا عميل جديد؟»
/// without opening him.
///
/// **A count nobody sent is a dash, not a nought.** A reader without `orders.view` is not sent
/// the key at all, and neither is the response to saving the form — so the column keeps its
/// place, and says it was not told.
class _OrdersField extends StatelessWidget {
  const _OrdersField({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    if (customer.lastOrderAgo case final silence?) {
      return _Field(label: 'آخر طلبية', value: silence);
    }

    final count = customer.ordersCount;

    return _Field(
      label: 'الطلبيات',
      value: switch (count) {
        null => '–',
        // Not «٠ طلبية»: a numeral standing for nothing is read as a number before it is read as
        // an absence, and Arabic has a shorter way to say it.
        0 => 'لا طلبيات',
        _ => '${count.grouped} طلبية',
      },
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
