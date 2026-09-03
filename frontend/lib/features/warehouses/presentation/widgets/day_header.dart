import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Whether a row at [at] is the first of its day on a feed read newest first — the row above
/// it, if any, happened at [previous]. Compared in local time, because a day is what the
/// person reading the feed calls a day.
bool startsNewDay(DateTime? previous, DateTime at) {
  if (previous == null) return true;
  final x = previous.toLocal();
  final y = at.toLocal();

  return x.year != y.year || x.month != y.month || x.day != y.day;
}

/// «اليوم», «أمس», or the date — above the first row of each day, so the rows underneath can
/// keep only the time. The one piece of sequence a list of cards never had.
class DayHeader extends StatelessWidget {
  const DayHeader({required this.at, required this.first, super.key});

  final DateTime at;

  /// Whether this is the top of the list, which needs less air above it than a break between
  /// two days.
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 8.h : 22.h, bottom: 4.h),
      child: Text(
        at.relativeDayLabel,
        style: context.textTheme.titleSmall?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
