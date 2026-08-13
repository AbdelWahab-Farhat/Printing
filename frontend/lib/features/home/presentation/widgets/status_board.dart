import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/appear.dart';
import 'package:printing/features/home/models/home_summary.dart';

/// Where the work in progress is sitting, one card per status.
///
/// Rendered from a list rather than a fixed set of cards: the statuses are the business's to
/// change, so a new one appears here as a row from the server rather than as a release of this
/// app — which is the whole reason the counts arrive as a list and not as named fields.
///
/// **Every card is the same white, and none of them shouts.** Tinting the urgent ones turned the
/// board into a checkerboard where the colour was doing the reading. A red dot replaced the tint
/// and was removed in turn: it marked a *status*, so «جديدة» wore it while counting zero — a
/// warning about nothing, which teaches the reader to stop believing the mark.
///
/// What is urgent is a judgement about a number, and this board's job is to show the numbers.
class StatusBoard extends StatelessWidget {
  const StatusBoard({required this.statuses, this.onOpen, super.key});

  final List<OrderStatusCount> statuses;

  /// Opens the orders behind one card. Null leaves the board readable and inert — which is what
  /// it was, and is still the right answer on a screen that cannot navigate.
  final ValueChanged<OrderStatusCount>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 4.w, bottom: 12.h),
          child: Text(
            'حالات الطلبات',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 18.h,
          crossAxisSpacing: 18.w,
          childAspectRatio: 1.7,
          children: [
            for (final (index, status) in statuses.indexed)
              Appear(
                index: index,
                child: _StatusCard(
                  status: status,
                  // A card counting nothing opens a screen saying so, which is a tap that
                  // teaches the reader nothing they did not already see.
                  onTap: onOpen == null || status.count == 0 ? null : () => onOpen!(status),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, this.onTap});

  final OrderStatusCount status;

  /// Null on a card with nothing to open — an empty status, or a board that was handed no
  /// destination. The ink is left off with it, so a card that does not respond does not look
  /// like one that does.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(18.r);

    final card = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
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
    );

    if (onTap == null) return card;

    // The ink goes *over* the card rather than under it: the card paints its own background and
    // its own shadow, and a Material underneath would draw a second surface behind both.
    return Stack(
      children: [
        card,
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
