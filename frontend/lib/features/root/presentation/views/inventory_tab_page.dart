import 'package:dayaa/core/utils/context_extensions.dart';
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
///   المواد   — **ماذا**: the shelf itself, a material at a size. What a balance is of.
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

  /// **Two words, and nothing under them.** Each segment used to carry a line explaining what it
  /// was — «الرفّ نفسه، وعليه يقوم الرصيد» and the like. Written once they read well; met on
  /// every visit they are a paragraph between the person and the list they came for, and after
  /// the second day nobody reads them.
  ///
  /// **«المواد» is the second one, and that is the whole naming.** What a storekeeper counts,
  /// orders and runs out of is a **مادة** — «كيس شحن 25×35» — and «كيس شحن» on its own is the
  /// **تصنيف** it is filed under. Calling the sized thing «صنف» put the everyday word on the
  /// screen nobody visits and left the screen with the balances named after a category.
  ///
  /// **And التصنيفات is no longer one of them.** A category is a thing the server keeps working
  /// with and nobody is asked about: which product sizes draw on a material is now said on the
  /// material itself, all of them at once, instead of one product at a time. The screen and its
  /// route still exist — a deep link resolves and the data behind it is untouched — but nothing
  /// navigates there.
  ///
  /// **This list and [IndexedStack]'s children are one thing in two places.** A label with no
  /// body behind it is a `RangeError` the moment somebody taps it, and neither the analyzer nor
  /// a widget test that never taps the third segment would say so — see [_bodies].
  static const List<String> _segments = ['المخازن', 'المواد'];

  /// One body per label in [_segments], in that order.
  ///
  /// **Kept beside the labels rather than inline**, because the two drifted apart once already:
  /// a segment was removed from the stack and left in the strip, and the tab looked perfectly
  /// correct until the third one was tapped. Named together, the mismatch is visible at a glance
  /// — and asserted below.
  static const List<Widget> _bodies = [
    WarehousesPage(),
    StockItemsPage(isEmbedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    assert(
      _segments.length == _bodies.length,
      'every segment needs a body: ${_segments.length} labels, ${_bodies.length} bodies',
    );

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
              // **Spans the row rather than shrink-wrapping its three words.** Sized to content
              // it sat as a small island under a centred title, reading as a chip somebody had
              // dropped there; full width it is plainly the switch for the list beneath it, and
              // the three targets divide the row evenly instead of being three narrow ones in
              // the middle.
              expandedInsets: EdgeInsets.zero,
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
          child: IndexedStack(index: _segment, children: _bodies),
        ),
      ],
    );
  }
}
