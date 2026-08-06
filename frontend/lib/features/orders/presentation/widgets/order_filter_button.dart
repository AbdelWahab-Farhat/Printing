import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/widgets/order_status_chip.dart';

/// Picking which status the list shows.
///
/// **A round button beside the search box, opening a sheet — not a row on the page.** The
/// statuses do not fit as chips across a phone: that was tried first and did not survive contact
/// with the real vocabulary, the ones past the middle living off the right edge of a row nothing
/// suggested was scrollable. A dropdown that opened in place worked, but pushed the list down
/// every time it was used. A button costs one glance to notice and nothing from the layout
/// beneath it; the sheet it opens is a scrolling list, so the vocabulary can grow without the
/// screen having to be redesigned around it.
///
/// **Filled when a status is picked, neutral on «الكل»**, so whether the list is narrowed is
/// answered before the sheet is even opened. The sheet itself carries the same per-row counts
/// the dropdown had — without them, learning there are no returns today cost a tap, a request
/// and an empty screen — plus a way back to «الكل» once something narrower is picked.
///
/// Colours come from the scheme, never from the design's hex values — the theme is generated
/// and gets replaced wholesale, and a literal here would survive that and quietly stop matching
/// everything around it.
class OrderFilterButton extends StatelessWidget {
  const OrderFilterButton({
    required this.selected,
    required this.selectedPayments,
    required this.counts,
    required this.onApplied,
    super.key,
  });

  /// Which status the list is narrowed to, or null for «الكل».
  final OrderStatus? selected;

  /// Which payment states are ticked. Empty means every one of them.
  final Set<PaymentStatus> selectedPayments;

  final ValueListenable<OrderCounts> counts;

  /// Both axes at once. One callback rather than two, because the sheet answers them together
  /// and two would fetch the list twice for a single tap on «تطبيق».
  final void Function(OrderStatus? status, Set<PaymentStatus> payments) onApplied;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<_FilterChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Listens rather than reading once: the counts can still be in flight when the button is
      // tapped, and the sheet should not open frozen on the empty placeholder.
      builder: (_) => ValueListenableBuilder<OrderCounts>(
        valueListenable: counts,
        builder: (context, value, _) =>
            _FilterSheet(selected: selected, selectedPayments: selectedPayments, counts: value),
      ),
    );

    if (picked != null) onApplied(picked.status, picked.payments);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = selected != null || selectedPayments.isNotEmpty;

    return Material(
      color: isActive ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _open(context),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(13.w),
          child: Icon(
            AppIcons.filter,
            size: 22.sp,
            color: isActive ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// What the sheet answers with: both axes, together.
class _FilterChoice {
  const _FilterChoice(this.status, this.payments);

  final OrderStatus? status;
  final Set<PaymentStatus> payments;
}

/// Two axes on one sheet: where the work stands, and where the money stands.
///
/// **The payment rows are ticks, not a second single choice.** «أرِني ما لم يُدفع» means unpaid
/// *and* part-paid in practice, and a radio list would make somebody run the list twice to see
/// one queue.
///
/// **And the two are applied together.** The status rows used to answer and close the sheet on
/// one tap, which was right while there was one question; with two, closing on the first would
/// make the second unreachable without opening the sheet again. Hence «تطبيق» at the bottom —
/// and it is the only reason this sheet became stateful.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.selected,
    required this.selectedPayments,
    required this.counts,
  });

  final OrderStatus? selected;
  final Set<PaymentStatus> selectedPayments;
  final OrderCounts counts;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late OrderStatus? _status = widget.selected;
  late Set<PaymentStatus> _payments = {...widget.selectedPayments};

  bool get _isFiltered => _status != null || _payments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      child: FractionallySizedBox(
        // The sheet grew a second section and a button; left to wrap its content it would run
        // past the top of a short phone and clip the first row it drew.
        heightFactor: 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'تصفية الطلبيات',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  // Only worth offering once there is something to clear.
                  if (_isFiltered)
                    TextButton(
                      onPressed: () => setState(() {
                        _status = null;
                        _payments = <PaymentStatus>{};
                      }),
                      child: const Text('مسح الفلاتر'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
                children: [
                  const _SectionTitle(title: 'حالة الطلبية'),
                  // «الكل» first and status-less, then the statuses in the order the machine
                  // walks them — so the sheet reads as the route an order takes rather than as
                  // an alphabetised list of words.
                  _Row(
                    status: null,
                    count: widget.counts.forStatus(null),
                    isSelected: _status == null,
                    onTap: () => setState(() => _status = null),
                  ),
                  for (final status in OrderStatus.filterable)
                    _Row(
                      status: status,
                      count: widget.counts.forStatus(status),
                      isSelected: status == _status,
                      onTap: () => setState(() => _status = status),
                    ),
                  SizedBox(height: 8.h),
                  const _SectionTitle(title: 'حالة الدفع'),
                  // Three, not four: «مدفوعة بالزيادة» is not a queue anybody works — see
                  // PaymentStatus.filterable.
                  for (final status in PaymentStatus.filterable)
                    _PaymentRow(
                      status: status,
                      count: widget.counts.forPaymentStatus(status),
                      isSelected: _payments.contains(status),
                      onTap: () => setState(() {
                        _payments.contains(status)
                            ? _payments.remove(status)
                            : _payments.add(status);
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_FilterChoice(_status, _payments)),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: const Text('تطبيق'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        title,
        style: context.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One payment state, with how many orders stand in it.
///
/// A **checkbox**, unlike the status rows above, and the shape says so: these combine and those
/// do not.
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.status,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentStatus status;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: isSelected ? scheme.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20.sp,
                color: isSelected ? scheme.primary : scheme.outline,
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  // The enum's own Arabic here, not an order's `payment_status_label`: this
                  // sheet has no order in hand to read one from.
                  status.label,
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$count',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One status, with how many orders stand in it. Null is «الكل».
class _Row extends StatelessWidget {
  const _Row({
    required this.status,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final OrderStatus? status;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: isSelected ? scheme.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          child: Row(
            children: [
              // The dot carries the same colour the status chip on a card will have, so the
              // filter and the list agree without the reader having to learn two legends.
              Container(
                width: 9.w,
                height: 9.w,
                decoration: BoxDecoration(color: _dotColour(scheme), shape: BoxShape.circle),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  // The enum's own Arabic, like the payment rows above: a row reading zero has
                  // no order behind it to borrow a `status_label` from, and that row is exactly
                  // the one worth showing.
                  status?.label ?? 'الكل',
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$count',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 8.w),
              // The slot is held whether or not it is filled, so the counts stay in one column
              // instead of shifting sideways as the selection moves.
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: isSelected
                    ? DecoratedBox(
                        decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, size: 11.sp, color: scheme.onPrimary),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// «الكل» has no status of its own, so it takes a neutral dot rather than borrowing one
  /// status's colour and implying it means that status.
  Color _dotColour(ColorScheme scheme) {
    final current = status;
    if (current == null) return scheme.outline;

    return OrderStatusChip.toneColour(scheme, current.tone).$2;
  }
}
