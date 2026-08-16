import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «التصنيف» — أكياس, ستيكرات ومطبوعات أخرى, مطبوعة — behind the button beside the search box.
///
/// **A row of chips became a sheet for the reason the chips were a row**: the headings are the
/// shop's to add to, and a horizontal strip that has to be scrolled hides the ones past the edge
/// while eating a band of the catalogue whether or not anybody is filtering. The round button is
/// what `CustomersFilterButton` and `OrderFilterButton` already settled on, so the catalogue does
/// not teach a fourth gesture — filled when the list is narrowed, so the question is answered
/// before the sheet is opened at all.
///
/// **Built from the server's list rather than from an enum**, because the headings are rows the
/// business curates: a sheet spelled out in code would go stale the first time somebody adds one
/// from «تصنيفات المنتجات».
///
/// It takes no room at all while there is nothing to choose between — one heading and «الكل»
/// filter to the same list, and a control that cannot change anything is worse than none.
class ProductCategoryFilterButton extends StatelessWidget {
  const ProductCategoryFilterButton({
    required this.categories,
    required this.selected,
    required this.onApplied,
    super.key,
  });

  /// The headings on offer. Whatever `ProductCategoriesCubit` last loaded.
  final List<ProductCategory> categories;

  /// The id the catalogue is narrowed to, or null for «الكل». What the sheet opens on.
  final int? selected;

  /// The heading picked, on «تطبيق» rather than on the tap that picked it — one callback, one
  /// fetch of the list.
  final ValueChanged<int?> onApplied;

  Future<void> _open(BuildContext context) async {
    // A nullable id cannot say «لم يُطبَّق» by itself, so the sheet answers with a one-element
    // list and dismissal answers with null.
    final picked = await showModalBottomSheet<List<int?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Material's own handle rather than a hand-drawn bar: the sheet does not fill the screen,
      // so the gesture that dismisses it needs saying out loud.
      showDragHandle: true,
      builder: (_) => _FilterSheet(categories: categories, selected: selected),
    );

    if (picked != null) onApplied(picked.single);
  }

  @override
  Widget build(BuildContext context) {
    if (categories.length < 2) return const SizedBox.shrink();

    final scheme = context.colorScheme;
    final isNarrowed = selected != null;

    return Material(
      color: isNarrowed ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _open(context),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(13.w),
          child: Icon(
            AppIcons.filter,
            size: 22.sp,
            color: isNarrowed ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// One axis, laid out the way the customers sheet lays out its two.
///
/// **«الكل» leads and is what clears the filter** — tapping the heading that is already picked
/// is not a way back, because that would leave two ways to say the same thing.
///
/// The height is content-sized and capped rather than a fixed fraction: a shop with three
/// headings gets a short sheet, and one with twenty scrolls rather than pushing «تطبيق» out of
/// reach.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.categories, required this.selected});

  final List<ProductCategory> categories;
  final int? selected;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int? _selected = widget.selected;

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
                      'تصفية المنتجات',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  // Only worth offering once there is something to clear.
                  if (_selected != null)
                    TextButton(
                      // Compact: this row is a caption and a way out, not a toolbar, and at the
                      // default density the button's tap target sets the height of a band that
                      // is otherwise empty.
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() => _selected = null),
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
                    const FilterSectionTitle(title: 'التصنيف'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        // «الكل» first and opinion-less, then the headings it splits into — the
                        // same shape «الكل / لديهم طلبات / بدون طلبات» takes on the customers
                        // sheet.
                        FilterOptionChip(
                          label: 'الكل',
                          isSelected: _selected == null,
                          onTap: () => setState(() => _selected = null),
                        ),
                        for (final category in widget.categories)
                          FilterOptionChip(
                            label: category.name,
                            isSelected: _selected == category.id,
                            onTap: () => setState(() => _selected = category.id),
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
                onPressed: () => Navigator.of(context).pop([_selected]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
