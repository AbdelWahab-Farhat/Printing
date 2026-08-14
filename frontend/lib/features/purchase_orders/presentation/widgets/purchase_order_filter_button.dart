import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Picking which state the purchase-order list shows.
///
/// **A round button beside the search box, opening a sheet — not a row on the page.** This screen
/// had the scrolling row of chips first, and it failed here exactly as it failed on the orders
/// list: «الكل» sat under the thumb while «ملغى» lived off the left edge of a row nothing
/// suggested continued, and the whole band cost 52dp of every screen to say something that is
/// «الكل» almost all the time. The button costs one glance and nothing from the list beneath it;
/// the sheet wraps its options over as many lines as they need.
///
/// **Filled when a state is picked, neutral on «الكل»**, so whether the list is narrowed is
/// answered before the sheet is opened — which matters now the states are behind a tap.
///
/// No per-option counts, unlike [OrderFilterButton]. The endpoint can produce them, but this list
/// is short enough that the answer is on screen already, and a request per sheet-open to say
/// «ملغى ٠» is not worth it. [FilterOptionChip.count] is optional for this case.
class PurchaseOrderFilterButton extends StatelessWidget {
  const PurchaseOrderFilterButton({
    required this.selected,
    required this.onApplied,
    super.key,
  });

  /// Which state the list is narrowed to, or null for «الكل».
  final PurchaseOrderStatus? selected;

  final ValueChanged<PurchaseOrderStatus?> onApplied;

  /// The sheet's own box, so a test can find it without depending on its wording.
  @visibleForTesting
  static const Key sheetKey = Key('purchase_order_filter_sheet');

  /// What the sheet answers with when «الكل» is picked.
  ///
  /// A sentinel rather than null, because `showModalBottomSheet` answers null when the sheet is
  /// *dismissed* — and «تطبيق» on «الكل» is a decision, while swiping the sheet away is not.
  /// Without it, clearing the filter and changing your mind would do the same thing.
  @visibleForTesting
  static const Object allSentinel = Object();

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(selected: selected),
    );

    if (picked == null) return;

    onApplied(picked == allSentinel ? null : picked as PurchaseOrderStatus);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = selected != null;

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

/// One question — where the order stands — as wrapped chips.
///
/// Stateful for the same reason the orders sheet is: the choice is applied on «تطبيق» rather than
/// on the tap, so «مسح الفلاتر» has something to clear and a mis-tap can be corrected without
/// reopening the sheet.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.selected});

  final PurchaseOrderStatus? selected;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late PurchaseOrderStatus? _status = widget.selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: PurchaseOrderFilterButton.sheetKey,
      // The drag handle above already clears the top.
      top: false,
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
                    'تصفية أوامر الشراء',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Only worth offering once there is something to clear.
                if (_status != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => setState(() => _status = null),
                    child: const Text('مسح الفلاتر'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FilterSectionTitle(title: 'حالة أمر الشراء'),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    // «الكل» first, then the states in the order the machine walks them — so the
                    // sheet reads as the route an order takes rather than as a list of words.
                    FilterOptionChip(
                      label: 'الكل',
                      isSelected: _status == null,
                      onTap: () => setState(() => _status = null),
                    ),
                    for (final status in PurchaseOrderStatus.choices)
                      FilterOptionChip(
                        // The enum's own Arabic: this sheet has no order in hand to read a
                        // `status_label` from, and has to name all four before any is loaded.
                        label: status.label,
                        isSelected: status == _status,
                        onTap: () => setState(() => _status = status),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
            child: AppButton(
              label: 'تطبيق',
              onPressed: () => Navigator.of(
                context,
              ).pop(_status ?? PurchaseOrderFilterButton.allSentinel),
            ),
          ),
        ],
      ),
    );
  }
}
