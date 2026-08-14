import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Both axes of the rates filter, answered together.
typedef RateFilterChoice = ({ManufacturingCostType? costType, bool? isActive});

/// Narrowing the rates table.
///
/// **A round button opening a sheet, not a row of chips on the page.** Five kinds of cost plus
/// three states of activity is more than fits across a phone, and the scrolling chip row that
/// would hold them puts its last options off the right edge with nothing to say the row
/// continues. A button costs one glance and nothing from the layout beneath it.
///
/// **Filled when something is picked**, so whether the list is narrowed is answered before the
/// sheet is opened — which matters here more than on most lists, because a narrowed ladder is
/// missing rungs and reads exactly like a table with gaps in it.
class ManufacturingCostRateFilterButton extends StatelessWidget {
  const ManufacturingCostRateFilterButton({
    required this.costType,
    required this.isActive,
    required this.onApplied,
    super.key,
  });

  /// Which kind of cost the list is narrowed to, or null for «الكل».
  final ManufacturingCostType? costType;

  /// Whether the list is narrowed to the rates still applying. Null shows both.
  final bool? isActive;

  /// One callback rather than two, because the sheet answers both at once and two would fetch
  /// the list twice for a single tap on «تطبيق».
  final ValueChanged<RateFilterChoice> onApplied;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<RateFilterChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(costType: costType, isActive: isActive),
    );

    if (picked != null) onApplied(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isFiltered = costType != null || isActive != null;

    return Material(
      color: isFiltered ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _open(context),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(13.w),
          child: Icon(
            AppIcons.filter,
            size: 22.sp,
            color: isFiltered ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Two questions on one sheet: which kind of cost, and whether it still applies.
///
/// Both are single choices with «الكل» first — unlike the orders filter, nothing here combines,
/// because a rate has exactly one kind and is either applying or not.
///
/// The height is content-sized and capped, so a longer list of cost kinds later grows the sheet
/// rather than silently pushing «تطبيق» out of reach.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.costType, required this.isActive});

  final ManufacturingCostType? costType;
  final bool? isActive;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ManufacturingCostType? _costType = widget.costType;
  late bool? _isActive = widget.isActive;

  bool get _isFiltered => _costType != null || _isActive != null;

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
                      'تصفية المعدلات',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // Only worth offering once there is something to clear.
                  if (_isFiltered)
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() {
                        _costType = null;
                        _isActive = null;
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
                    const FilterSectionTitle(title: 'نوع التكلفة'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        FilterOptionChip(
                          label: 'الكل',
                          isSelected: _costType == null,
                          onTap: () => setState(() => _costType = null),
                        ),
                        for (final type in ManufacturingCostType.choices)
                          FilterOptionChip(
                            // The enum's own Arabic, not a rate's `cost_type_label`: this sheet
                            // has no rate in hand to read one from, and the kind worth filtering
                            // for is often the one with no rows yet.
                            label: type.label,
                            isSelected: type == _costType,
                            onTap: () => setState(() => _costType = type),
                          ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    const FilterSectionTitle(title: 'الحالة'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final (label, value) in const [
                          ('الكل', null),
                          ('يُطبَّق', true),
                          ('موقوف', false),
                        ])
                          FilterOptionChip(
                            label: label,
                            isSelected: _isActive == value,
                            onTap: () => setState(() => _isActive = value),
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
                onPressed: () => Navigator.of(context).pop(
                  (costType: _costType, isActive: _isActive),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
