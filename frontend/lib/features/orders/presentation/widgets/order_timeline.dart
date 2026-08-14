import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Every move the order made, oldest first.
///
/// Oldest first deliberately, unlike most feeds: this is read as a story of what happened to a
/// job, and a story told backwards has to be re-assembled by the reader. The newest row is at
/// the bottom, which is also where the eye already is after the sections above it.
///
/// The reason is shown when there is one — it is the whole point of recording a cancellation or
/// a return, and a timeline that showed only the statuses would answer "what" while leaving
/// "why" on a table nobody can reach.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({required this.records, super.key});

  final List<OrderTransitionRecord> records;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, record) in records.indexed)
          _Entry(record: record, isLast: index == records.length - 1),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.record, required this.isLast});

  final OrderTransitionRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                margin: EdgeInsets.only(top: 5.h),
                decoration: BoxDecoration(
                  color: isLast ? scheme.primary : scheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2.w, color: scheme.outlineVariant),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // The opening row has no "from", so it reads as an event rather than as a
                    // move out of nothing.
                    record.isOpening
                        ? 'تم إنشاء الطلبية'
                        : '${record.fromStatusLabel} ← ${record.toStatusLabel}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_meta(record) case final meta when meta.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      meta,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (record.reason case final reason?) ...[
                    SizedBox(height: 4.h),
                    Text(
                      reason,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `2026-08-02 · 14:30 · بواسطة أحمد` — when it happened, and who did it.
  ///
  /// One line, because they are one fact: «من فعل هذا، ومتى». Split in two they read as two
  /// entries, and this column is already made of short lines.
  ///
  /// **A move with nobody behind it says nothing rather than guessing.** The column is nullable
  /// on purpose — a seeder or a console command moves an order without a signed-in user — and
  /// attributing that to whoever happens to be reading the screen would be worse than the gap.
  String _meta(OrderTransitionRecord record) => [
    if (record.createdAt case final at?) at.stampLabel,
    if (record.user?.name case final name?) 'بواسطة $name',
  ].join(' · ');

  /// «2 أغسطس 2026 · 2:30 م», in the device's own local time — [AppDates], like every other
  /// date this app draws. A timeline is read as "in what order, and how long apart", and the
  /// month said in words is what makes two rows a week apart look a week apart.
}
