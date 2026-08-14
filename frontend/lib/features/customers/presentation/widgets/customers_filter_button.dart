import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Turning the customer register into a call sheet.
///
/// **The two questions somebody asks when they sit down to ring people**, and neither is
/// answerable by scrolling: which half of the register this is — those who buy and those who
/// never have — and who has not ordered for longest. Both are computed from the orders, so the
/// whole button is hidden from anybody who may not see them —
/// see `CustomersPage`, and `CustomerRepository.customers` for the 403 that would otherwise be
/// waiting behind it.
///
/// **A round button beside the search box, opening a sheet** — the shape `OrderFilterButton` and
/// `ManufacturingCostRateFilterButton` already settled on, so the third list on this phone to
/// grow a filter does not teach a third gesture. Filled when the list is narrowed, so whether it
/// is answered before the sheet is opened at all.
class CustomersFilterButton extends StatelessWidget {
  const CustomersFilterButton({required this.filter, required this.onApplied, super.key});

  /// What the sheet opens on — the answers already given, not a blank sheet.
  final CustomersFilter filter;

  /// Both questions at once. One callback rather than two, because the sheet answers them
  /// together and two would fetch the list twice for a single tap on «تطبيق».
  final ValueChanged<CustomersFilter> onApplied;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<CustomersFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Material's own handle rather than a hand-drawn bar: the sheet does not fill the screen,
      // so the gesture that dismisses it needs saying out loud.
      showDragHandle: true,
      builder: (_) => _FilterSheet(filter: filter),
    );

    if (picked != null) onApplied(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: filter.isNarrowed ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _open(context),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(13.w),
          child: Icon(
            AppIcons.filter,
            size: 22.sp,
            color: filter.isNarrowed ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Two axes on one sheet: which customers, and in what order.
///
/// **Both are single choices, and «الكل» / «الأحدث إضافة» are the ones the list opens on.**
/// Nothing here combines the way the payment states on the orders sheet do: a customer has
/// either ordered or not, and a list is in one order at a time.
///
/// **The two are applied together**, hence «تطبيق» at the bottom rather than a tap that closes
/// the sheet — closing on the first would make the second unreachable without opening it again.
///
/// The height is content-sized and capped rather than a fixed fraction: four chips are a short
/// sheet, and a third axis later should grow it rather than push «تطبيق» out of reach.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filter});

  final CustomersFilter filter;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool? _hasOrders = widget.filter.hasOrders;
  late bool _leastRecentFirst = widget.filter.leastRecentOrderFirst;

  CustomersFilter get _picked =>
      CustomersFilter(hasOrders: _hasOrders, leastRecentOrderFirst: _leastRecentFirst);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // The drag handle above already clears the top.
      top: false,
      child: ConstrainedBox(
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
                      'تصفية العملاء',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  // Only worth offering once there is something to clear.
                  if (_picked.isNarrowed)
                    TextButton(
                      // Compact: this row is a caption and a way out, not a toolbar, and at the
                      // default density the button's tap target sets the height of a band that
                      // is otherwise empty.
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() {
                        _hasOrders = null;
                        _leastRecentFirst = false;
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
                    const FilterSectionTitle(title: 'الطلبيات'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        // «الكل» first and opinion-less, then the two halves it splits into —
                        // the same shape «الكل / يُطبَّق / موقوف» takes on the rates sheet.
                        for (final (label, value) in const [
                          ('الكل', null),
                          ('لديهم طلبات', true),
                          ('بدون طلبات', false),
                        ])
                          FilterOptionChip(
                            label: label,
                            isSelected: _hasOrders == value,
                            onTap: () => setState(() => _hasOrders = value),
                          ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    const FilterSectionTitle(title: 'الترتيب'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final (label, value) in const [
                          ('الأحدث إضافة', false),
                          // Not «الأقدم» alone: the list is not sorted by how old the *customer*
                          // is, which is what that word would be read as beside «الأحدث إضافة».
                          ('الأقدم طلباً', true),
                        ])
                          FilterOptionChip(
                            label: label,
                            isSelected: _leastRecentFirst == value,
                            onTap: () => setState(() => _leastRecentFirst = value),
                          ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'الزبائن الذين طالت المدة منذ آخر طلبية لهم أولاً، ومن لم يطلب أبداً في الآخر.',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
              child: AppButton(
                label: 'تطبيق',
                onPressed: () => Navigator.of(context).pop(_picked),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
