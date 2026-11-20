import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/models/order_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What kind of goods an order is — «مطبوع», «سادة» or «تصنيع» — beside its status.
///
/// **Read off the road the server stamped at intake, not off the lines.** The three kinds map
/// one-to-one onto [OrderFlow]: any printed line puts an order on the standard road, all-plain
/// orders skip production, and all-vendor orders go out to be made. So the badge holds still
/// from creation to settlement, exactly as the road does, and needs nothing new on the wire.
///
/// **Neutral on purpose.** The status beside it owns the colour on this row; this is a fact
/// about the order, not an alarm, and it should read as quieter than «مستعجل» or «محذوفة».
///
/// An unknown road shows nothing rather than a guess.
class OrderProductKindBadge extends StatelessWidget {
  const OrderProductKindBadge({required this.flow, this.besideBanner = false, super.key});

  final OrderFlow flow;

  /// The list card's size, where it stands beside the full-width status band — the same switch
  /// `OrderDeletedBadge` has, so the row keeps one height.
  final bool besideBanner;

  /// The Arabic word for each road, or null for one this build does not know.
  static String? labelFor(OrderFlow flow) => switch (flow) {
    OrderFlow.standard => 'مطبوع',
    OrderFlow.noProduction => 'سادة',
    OrderFlow.outsourced => 'تصنيع',
    OrderFlow.unknown => null,
  };

  @override
  Widget build(BuildContext context) {
    final label = labelFor(flow);
    if (label == null) return const SizedBox.shrink();

    final scheme = context.colorScheme;

    return Container(
      padding: besideBanner
          ? EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h)
          : EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(besideBanner ? 12.r : 10.r),
      ),
      child: Text(
        label,
        style: context.textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
