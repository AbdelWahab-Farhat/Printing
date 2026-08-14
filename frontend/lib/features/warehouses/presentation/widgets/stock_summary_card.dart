import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What this warehouse holds, before anybody scrolls.
///
/// The screen under it answers one size at a time; this answers the whole place, and it is the
/// only thing here that a list cannot be read for. Three claims, in falling order of loudness:
///
///   * **the total**, as the one big number — what a stocktake opens the screen for,
///   * **how many sizes** that is spread over, because a warehouse holding six sizes of one bag
///     is a small warehouse however many thousands of bags that is,
///   * **the state of the shelves**, as a bar of the line count.
///
/// **The bar is a part-to-whole and nothing else.** Not a trend — a balance has no history on
/// this screen — and never a second scale: the segments are counts of lines, so they add up to
/// the total by construction. `lowOnlyCount` is what keeps them from overlapping, since the
/// server's two attention counts deliberately do.
///
/// **Nothing is said in colour alone.** Every segment has a word and a number beside it, and a
/// segment with nothing in it is left out rather than drawn at zero — «0 نافد» is a reassurance
/// nobody asked for, taking width from the two numbers that matter. Colours come from the
/// scheme's own roles, never a hex: the theme is generated and gets replaced wholesale.
class StockSummaryCard extends StatelessWidget {
  const StockSummaryCard({required this.summary, super.key});

  final WarehouseStockSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // A warehouse nothing has ever arrived at gets no card. The list below already says «لا
    // توجد أرصدة في هذا المخزن بعد», and a header repeating it — over a bar of nothing — is the
    // same sentence twice and a shape that means nothing.
    if (!summary.hasLines) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: _Numbers(summary: summary),
    );
  }
}

class _Numbers extends StatelessWidget {
  const _Numbers({required this.summary});

  final WarehouseStockSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final segments = _segmentsOf(summary, scheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'إجمالي القطع',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    summary.totalQuantityLabel,
                    // A Latin run: `12,450` renders as `450,12` without this, which is a
                    // different number rather than a rendering glitch.
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '${summary.totalLines.grouped} صنفاً',
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _HealthBar(segments: segments),
        SizedBox(height: 8.h),
        _Legend(segments: segments),
      ],
    );
  }
}

/// One state of the shelves: how many lines are in it, what it is called, and its colour.
@immutable
class _Segment {
  const _Segment({required this.count, required this.label, required this.colour});

  final int count;
  final String label;
  final Color colour;
}

/// The three states, largest share first, with the empty ones dropped.
///
/// Ordered by meaning rather than by size, so the bar reads the same way every time it is
/// looked at: what is fine, then what is asking, then what has run out.
List<_Segment> _segmentsOf(WarehouseStockSummary summary, ColorScheme scheme) {
  return <_Segment>[
    _Segment(count: summary.healthyCount, label: 'سليم', colour: scheme.primary),
    _Segment(count: summary.lowOnlyCount, label: 'تحت الحد', colour: scheme.warn),
    _Segment(count: summary.outOfStockCount, label: 'نافد', colour: scheme.error),
  ].where((segment) => segment.count > 0).toList();
}

/// A part-to-whole of the line count, in one bar.
///
/// `Expanded` with each segment's count as its flex — the widths are the numbers, with no
/// arithmetic in between that could round one of them away. The 2px gaps are surface, not a
/// border: two coloured fills that touch read as one shape with a seam.
class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.segments});

  final List<_Segment> segments;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        height: 8.h,
        // A rail under the segments, so the bar is a shape even while the numbers are odd.
        child: ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Row(
            children: [
              for (final (index, segment) in segments.indexed) ...[
                if (index > 0) SizedBox(width: 2.w),
                Expanded(
                  flex: segment.count,
                  child: ColoredBox(color: segment.colour),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The bar's key: a dot, a count, a word. Never the colour on its own.
class _Legend extends StatelessWidget {
  const _Legend({required this.segments});

  final List<_Segment> segments;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Wrap(
      spacing: 14.w,
      runSpacing: 4.h,
      children: [
        for (final segment in segments)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(color: segment.colour, shape: BoxShape.circle),
              ),
              SizedBox(width: 6.w),
              Text(
                // One Text, not two: a screen reader reading «١٨» and «سليم» as separate nodes
                // has read two facts rather than one.
                '${segment.count.grouped} ${segment.label}',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
