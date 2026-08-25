import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/stock_item_groups/presentation/views/stock_item_groups_page.dart';
import 'package:dayaa/features/stock_items/presentation/views/stock_items_page.dart';
import 'package:dayaa/features/warehouses/presentation/views/warehouses_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// المخزون — one tab over the three questions a storekeeper actually asks.
///
/// **They were three doors in two different places, and that was the mistake.** المخازن was a
/// tab; أصناف المخزون and مجموعات الأصناف were rows in the drawer, filed near المنتجات because
/// they are reference data. But they are not three subjects — they are one subject at three
/// zoom levels, and every one of them is about the same heap of bags:
///
///   المخازن  — **أين**: the rooms, and what each holds
///   الأصناف  — **ماذا**: the shelf itself, a material at a size. This is what a balance is of.
///   المواد   — **من أي شيء**: the family a shelf is a size of, and the thing a product names
///
/// That reading is what the three screens teach by being used. None of it is printed on them —
/// see [_segments].
///
/// Putting the middle one behind a hamburger while its balances sat under a tab meant the
/// screen that *explains* «كيس شحن 25*35» was the hardest of the three to find, and somebody
/// reading أصناف المخزون out of context read it as a duplicate of المنتجات.
///
/// **Segments rather than nested navigation**, because the three are siblings and a person
/// moves between them constantly — «هذا الرصيد لأي صنف؟ وهذا الصنف من أي مادة؟» is one train of
/// thought, and it should not cost a back-press each way.
///
/// The three bodies are the real screens, embedded — see [StockItemsPage.isEmbedded]. Nothing
/// here is a second implementation of a list, so a fix to the أصناف screen is a fix here too,
/// and the standalone routes a deep link uses keep working unchanged.
class InventoryTabPage extends StatefulWidget {
  const InventoryTabPage({super.key});

  @override
  State<InventoryTabPage> createState() => _InventoryTabPageState();
}

class _InventoryTabPageState extends State<InventoryTabPage> {
  /// المخازن first, and it stays the landing segment: it is the one opened every day, and the
  /// other two are consulted when something about a shelf needs explaining.
  int _segment = 0;

  /// **Three words, and nothing under them.** Each segment used to carry a line explaining what
  /// it was — «الرفّ نفسه، وعليه يقوم الرصيد» and the like. Written once they read well; met on
  /// every visit they are a paragraph between the person and the list they came for, and after
  /// the second day nobody reads them. The words «صنف» and «مادة» are learned from using the
  /// screens, not from a caption repeated above them.
  static const List<String> _segments = ['المخازن', 'الأصناف', 'المواد'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // **A switch, not a headline.** `SegmentedButton`'s default is a 48dp Material target
        // with generous padding — right for a form control the eye has to find, wrong for three
        // words that sit under an app bar and get used constantly. Sized down to a strip: the
        // list below it is the subject of this screen, and the chrome should cost as few pixels
        // as it can while staying comfortably tappable.
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 6.h),
          child: SizedBox(
            height: 34.h,
            child: SegmentedButton<int>(
              segments: [
                for (var i = 0; i < _segments.length; i++)
                  ButtonSegment<int>(value: i, label: Text(_segments[i])),
              ],
              selected: {_segment},
              // Never empty: one of the three is always the answer, so an unselected state would
              // be a tab showing nothing with no way back.
              multiSelectionEnabled: false,
              emptySelectionAllowed: false,
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                textStyle: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onSelectionChanged: (choice) => setState(() => _segment = choice.first),
            ),
          ),
        ),
        Expanded(
          // **IndexedStack, not a swap.** Each body owns a cubit that fetches on create, so
          // rebuilding the subtree on every segment tap would re-request the list each time and
          // throw away a scroll position and a filter the person had just set. This is the same
          // reason the shell keeps every tab alive.
          child: IndexedStack(
            index: _segment,
            children: const [
              WarehousesPage(),
              StockItemsPage(isEmbedded: true),
              StockItemGroupsPage(isEmbedded: true),
            ],
          ),
        ),
      ],
    );
  }
}
