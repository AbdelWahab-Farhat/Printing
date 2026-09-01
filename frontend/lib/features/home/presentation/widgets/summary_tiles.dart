import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/appear.dart';
import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The four numbers that describe the business at a glance.
///
/// Two by two rather than a row of four: at four across, the digits shrink to where 9651 and
/// 9,651 are the same smudge, and these numbers exist to be read from arm's length.
class SummaryTiles extends StatelessWidget {
  const SummaryTiles({
    required this.summary,
    this.onAllOrders,
    this.onCustomers,
    this.onDay,
    this.onMonth,
    super.key,
  });

  final HomeSummary summary;

  /// What each number opens. Null leaves that one inert — a tile with nowhere honest to go is
  /// better flat than tappable.
  final VoidCallback? onAllOrders;
  final VoidCallback? onCustomers;
  final VoidCallback? onDay;
  final VoidCallback? onMonth;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Tile(
        label: 'الطلبات الكلية',
        value: summary.totalOrders,
        onTap: onAllOrders,
      ),
      _Tile(
        label: 'عدد العملاء',
        value: summary.customersCount,
        onTap: onCustomers,
      ),
      // A day or a month with nothing in it opens a screen that says so, which is a tap that
      // teaches the reader nothing they cannot already see.
      _Tile(
        label: 'الطلبات اليومية',
        value: summary.dailyOrders,
        onTap: summary.dailyOrders == 0 ? null : onDay,
      ),
      _Tile(
        label: 'الطلبات الشهرية',
        value: summary.monthlyOrders,
        onTap: summary.monthlyOrders == 0 ? null : onMonth,
      ),
    ];

    return GridView.count(
      // Inside a scrolling column: it lays out at its natural height and lets the page scroll.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      // Wide and shallow: the tile holds a word and a number stacked in the middle of it, and
      // the height it used to carry was empty space between an icon at the top and a number
      // pushed to the bottom corner.
      childAspectRatio: 2.15,
      children: [
        for (final (index, tile) in tiles.indexed) Appear(index: index, child: tile),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);

    final tile = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      // The word over the number, both centred, and no icon beside either.
      //
      // The icon named the same thing the word already named — «الطلبات اليومية» next to a
      // calendar — so it spent the width of a glyph saying nothing, and it pulled the label off
      // centre while the number sat in the opposite corner. Stacked and centred, the four tiles
      // read as one block of four numbers instead of four little dashboards.
      // Both lines are `Flexible` and both shrink to fit rather than overflow.
      //
      // A tile this shallow is two lines of type inside a box whose height comes from its
      // width, so the phone, the font and the reader's text-size setting all get a vote in
      // whether they fit — and when they did not, the answer was a striped bar painted across
      // the number the tile exists to show. Shrinking a little is the honest failure here.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                // Grouped: 9651 is read as a shape, 9,651 as a number.
                value.grouped,
                textDirection: TextDirection.ltr,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;

    // Over the tile rather than under it, for the reason the status cards give: the tile paints
    // its own surface, and a Material beneath would draw a second one behind it.
    return Stack(
      // Tight constraints back onto the tile: a loose `Stack` lets a centred column collapse to
      // its two lines, and only the tappable tiles would shrink.
      fit: StackFit.expand,
      children: [
        tile,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(borderRadius: radius, onTap: onTap),
          ),
        ),
      ],
    );
  }
}
