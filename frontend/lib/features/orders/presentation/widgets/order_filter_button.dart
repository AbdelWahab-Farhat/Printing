import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/filter_option_chip.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/widgets/order_status_chip.dart';

/// Picking which status the list shows.
///
/// **A round button beside the search box, opening a sheet — not a row on the page.** The
/// statuses do not fit across a phone in one line: that was tried first, as a scrolling row of
/// chips, and did not survive contact with the real vocabulary — the ones past the middle lived
/// off the right edge of a row nothing suggested continued. A dropdown that opened in place
/// worked, but pushed the list down every time it was used. A button costs one glance to notice
/// and nothing from the layout beneath it; the sheet it opens wraps its options over as many
/// lines as they need, so the vocabulary can grow without the screen being redesigned around it.
///
/// **Filled when a status is picked, neutral on «الكل»**, so whether the list is narrowed is
/// answered before the sheet is even opened. The sheet itself carries the same per-option counts
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

  /// The sheet's own box, so a test can measure how much of the phone it takes. That is a
  /// tested property here rather than a matter of taste — see [_FilterSheet].
  @visibleForTesting
  static const Key sheetKey = Key('order_filter_sheet');

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<_FilterChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Material's own handle rather than a hand-drawn bar. The sheet no longer fills the screen,
      // so the gesture that dismisses it needs saying out loud.
      showDragHandle: true,
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
///
/// ## Chips in a wrap, not a column of rows
///
/// Every option used to be a full-width row: a dot, a word, a number, and a tick — and the rest
/// of the phone's width empty beside it. Fifteen of those plus three payment rows is more than a
/// screen, so the sheet was pinned at 90% of the phone and *still* scrolled, which put the queues
/// somebody actually works — the returns — below the fold on the way in, and «تطبيق» floating
/// over a list with no visible end.
///
/// Wrapped chips answer the same two questions in a little over half the height, and the shape
/// change is what buys it: a chip is as wide as its word, so «جاهزة» stops reserving the width of
/// «راجع لدى شركة التوصيل». Two or three land per line and the whole vocabulary is in one glance.
/// Nothing lives off the edge — this is a `Wrap`, not the scrolling row of chips that was tried
/// on the page itself and failed; that one ran off the right side with nothing to suggest it
/// continued.
///
/// The height is **content-sized and capped**, not a fixed fraction. The sheet is as tall as what
/// it has to say, and only starts scrolling on a phone too short to hold it — so a longer status
/// vocabulary later grows the sheet rather than silently pushing rows out of reach.
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
    return SafeArea(
      key: OrderFilterButton.sheetKey,
      // The drag handle above already clears the top.
      top: false,
      child: ConstrainedBox(
        // The cap, not the height: `Column` is `min` and the scroller is `Flexible`, so the sheet
        // measures itself against its chips and only reaches this on a phone short enough to
        // need it.
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 8.w, 0),
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
                      // Compact: this row is a caption and a way out, not a toolbar, and at the
                      // default density the button's 48px tap target sets the height of a band
                      // that is otherwise empty.
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() {
                        _status = null;
                        _payments = <PaymentStatus>{};
                      }),
                      child: const Text('مسح الفلاتر'),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FilterSectionTitle(title: 'حالة الطلبية'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        // «الكل» first and status-less, then the statuses in the order the
                        // machine walks them — so the sheet reads as the route an order takes
                        // rather than as an alphabetised list of words.
                        FilterOptionChip(
                          // The enum's own Arabic, not an order's `status_label`: this sheet has
                          // no order in hand to read one from, and a chip reading zero — which is
                          // exactly the one worth showing — has none behind it either.
                          label: 'الكل',
                          count: widget.counts.forStatus(null),
                          // «الكل» has no status of its own, so it takes a neutral dot rather
                          // than borrowing one status's colour and implying it means that status.
                          dot: context.colorScheme.outline,
                          isSelected: _status == null,
                          onTap: () => setState(() => _status = null),
                        ),
                        for (final status in OrderStatus.filterable)
                          FilterOptionChip(
                            label: status.label,
                            count: widget.counts.forStatus(status),
                            // The same colour the status chip on a card will have, so the filter
                            // and the list agree without the reader learning two legends.
                            dot: OrderStatusChip.toneColour(context.colorScheme, status.tone).$2,
                            isSelected: status == _status,
                            onTap: () => setState(() => _status = status),
                          ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    const FilterSectionTitle(title: 'حالة الدفع'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        // Three, not four: «مدفوعة بالزيادة» is not a queue anybody works — see
                        // PaymentStatus.filterable.
                        for (final status in PaymentStatus.filterable)
                          FilterOptionChip(
                            label: status.label,
                            count: widget.counts.forPaymentStatus(status),
                            // A tick rather than a dot, and it is the whole way this section says
                            // it combines: these chips add up where the ones above replace each
                            // other, and the shape has to carry that now the layout is identical.
                            isTicked: true,
                            isSelected: _payments.contains(status),
                            onTap: () => setState(() {
                              _payments.contains(status)
                                  ? _payments.remove(status)
                                  : _payments.add(status);
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
              child: AppButton(
                label: 'تطبيق',
                onPressed: () =>
                    Navigator.of(context).pop(_FilterChoice(_status, _payments)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
