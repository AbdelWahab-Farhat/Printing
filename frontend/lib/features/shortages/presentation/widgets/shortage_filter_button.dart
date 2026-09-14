import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_counts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Every question the نواقص list can be narrowed by, behind one button.
///
/// **This replaced two rows of chips, and the reason is the reason `PurchaseOrderFilterButton`
/// gives.** The list opened with a scrolling status row *and* a second row for the two queues:
/// 100dp of every screen spent saying «الكل», with «مكتمل» off the edge of a row nothing
/// suggested continued, and the two rows disagreeing about which of them was «the» filter. The
/// button costs one glance and nothing from the list beneath it, and the sheet wraps its options
/// over as many lines as they need.
///
/// **The counts came with them.** They are the one thing the chip row was good for — «كم نقصاً
/// جاري البحث عنه؟» — so they sit beside the statuses inside the sheet instead of being lost.
/// They are not asked for again when it opens: the list already holds the answer.
///
/// **Two questions stayed outside**, on the page itself, and for one reason: each is flipped
/// between while reading rather than set once and forgotten. المصدر — «يدوي» against «من طلبية»,
/// a shortage the shop wants against one a customer is waiting on — is two words wide and rides
/// in [ShortageFilterSelection] all the same, so the button still knows whether the list is
/// narrowed. الإسناد went out later, into the tab row above the rows: the unassigned queue is a
/// pile of work and the reader's own is their day, and neither is worth two taps and an «تطبيق».
/// It does **not** ride in the selection — the tabs own it, and the sheet must not hand back an
/// answer to a question it no longer asks.
///
/// **Filled when anything is set, neutral when nothing is**, so whether the list is narrowed is
/// answered before the sheet is opened.
class ShortageFilterButton extends StatelessWidget {
  const ShortageFilterButton({
    required this.selection,
    required this.counts,
    required this.onApplied,
    super.key,
  });

  final ShortageFilterSelection selection;

  /// What the board answered for the *current* question — the statuses' own numbers.
  final ShortageCounts counts;

  final ValueChanged<ShortageFilterSelection> onApplied;

  /// The sheet's own box, so a test can find it without depending on its wording.
  @visibleForTesting
  static const Key sheetKey = Key('shortage_filter_sheet');

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<ShortageFilterSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(selection: selection, counts: counts),
    );

    // Null is a dismissal, not an answer: «تطبيق» on an empty sheet is a decision — it clears
    // the filters — while swiping the sheet away is not.
    if (picked != null) onApplied(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = selection.isNarrowed;

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

/// The two questions the sheet asks, as one answer.
///
/// **الإسناد is not among them any more.** It sits in the tab row above the list — «مَن يلاحق
/// ماذا» is flipped between while reading rather than set once — and a filter with two homes is
/// a filter whose two homes disagree.
@immutable
class ShortageFilterSelection {
  const ShortageFilterSelection({this.status, this.source});

  /// Null is «الكل» — **completed ones included**, which is what the list opens on: the
  /// historical record is part of what the section is for.
  final ShortageStatus? status;

  /// `'manual'`, `'order'`, or null for both.
  final String? source;

  bool get isNarrowed => status != null || source != null;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.selection, required this.counts});

  final ShortageFilterSelection selection;
  final ShortageCounts counts;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

/// Stateful for the reason every filter sheet in this app is: the choice is applied on «تطبيق»
/// rather than on the tap, so «مسح الفلاتر» has something to clear and a mis-tap can be corrected
/// without reopening the sheet.
class _FilterSheetState extends State<_FilterSheet> {
  late ShortageStatus? _status = widget.selection.status;
  late String? _source = widget.selection.source;

  bool get _isNarrowed => _status != null || _source != null;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: ShortageFilterButton.sheetKey,
      // The drag handle above already clears the top.
      top: false,
      child: SingleChildScrollView(
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
                      'تصفية النواقص',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // Only worth offering once there is something to clear.
                  if (_isNarrowed)
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() {
                        _status = null;
                        _source = null;
                      }),
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
                  const FilterSectionTitle(title: 'حالة النقص'),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      FilterOptionChip(
                        label: 'الكل',
                        // The server's own total, never the four chips added up — so a status
                        // this build has never heard of is still inside the number.
                        count: widget.counts.total,
                        isSelected: _status == null,
                        onTap: () => setState(() => _status = null),
                      ),
                      for (final status in ShortageStatus.offered)
                        FilterOptionChip(
                          // The enum's own Arabic: this sheet has no shortage in hand to read a
                          // `status_label` from, and has to name all four before any is loaded.
                          label: status.label,
                          count: widget.counts.forStatus(status),
                          isSelected: status == _status,
                          onTap: () => setState(() => _status = status),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
              child: AppButton(
                label: 'تطبيق',
                onPressed: () => Navigator.of(context).pop(
                  ShortageFilterSelection(status: _status, source: _source),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
