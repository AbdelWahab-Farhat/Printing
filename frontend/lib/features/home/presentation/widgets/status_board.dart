import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/appear.dart';
import 'package:printing/features/home/models/home_summary.dart';

/// Where the work in progress is sitting, one card per status.
///
/// Rendered from a list rather than a fixed set of cards: these are the statuses the paper
/// workflow uses today, and they are expected to be replaced by the app's own. When that
/// happens the server sends different rows and this widget does not change — which is the whole
/// reason the counts arrive as a list and not as named fields.
///
/// **Every card is the same white.** Tinting the urgent ones turned the board into a checkerboard
/// where the colour was doing the reading, and at eight cards half of them were shouting. What
/// carries urgency now is a single dot: present or absent, in one place on the card, so it is
/// found by looking rather than by comparing two shades of the same green.
class StatusBoard extends StatelessWidget {
  const StatusBoard({required this.statuses, super.key});

  final List<OrderStatusCount> statuses;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();

    final needingAttention = statuses.where((status) => status.needsAttention).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 4.w, bottom: 12.h),
          child: Row(
            children: [
              Text(
                'حالات الطلبات',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Says what the dots below mean, once, instead of leaving them to be guessed.
              if (needingAttention > 0) _AttentionLegend(count: needingAttention),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.7,
          children: [
            for (final (index, status) in statuses.indexed)
              Appear(index: index, child: _StatusCard(status: status)),
          ],
        ),
      ],
    );
  }
}

class _AttentionLegend extends StatelessWidget {
  const _AttentionLegend({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: context.colorScheme.error),
        SizedBox(width: 6.w),
        Text(
          '$count تحتاج متابعة',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8.w,
      width: 8.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // A ring of the same colour at low alpha: the dot reads at a glance without being a
        // heavier mark than an 8pt circle should be.
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, spreadRadius: 2)],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final OrderStatusCount status;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (status.needsAttention)
            PositionedDirectional(top: 0, start: 0, child: _Dot(color: scheme.error)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status.count.toString(),
                textDirection: TextDirection.ltr,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  indent: 24.w,
                  endIndent: 24.w,
                  color: scheme.outlineVariant.withValues(alpha: 0.8),
                ),
              ),
              Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
