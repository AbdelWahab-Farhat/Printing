import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Why an order cannot go into a shared parcel beside [first], or null when it can.
///
/// **A courtesy, not the rule.** The server decides — one customer, one destination, one
/// recipient phone, each order ready and not already out — and refuses the whole group naming the
/// order that does not fit. This only stops a card being picked when the answer is already plain
/// on the screen, so the clerk is not sent to the server to learn what the list already said. The
/// phone is left to the server: it compares numbers as they would be sent, and a second copy of
/// that normalisation here would be a copy that disagrees.
String? whyNotSendTogether(Order order, {Order? first}) {
  if (order.isArchived) return 'الطلبية في الأرشيف';
  if (order.isOfficePickup) return 'الطلبية استلام مكتب';
  if (order.nawrisParcel?.isOpen ?? false) return 'الطلبية مُرسلة للنورس بالفعل';

  if (first == null || first.id == order.id) return null;

  if (order.customerId != first.customerId) return 'الطرد المشترك لزبون واحد';
  if (order.cityId != first.cityId || order.regionId != first.regionId) {
    return 'الطرد المشترك يذهب إلى عنوان واحد';
  }

  return null;
}

/// An [OrderCard] while orders are being picked to go out together.
///
/// **A tap picks instead of opening.** The mode is entered on purpose from the list's own button,
/// so the tap changing meaning is something the clerk just asked for — and the long press stays
/// the card's text selection, which is what it already was.
///
/// A card that cannot join is dimmed rather than hidden: a list that loses rows the moment
/// picking starts reads as a list that changed, and the tap still says why.
class PickableOrderCard extends StatelessWidget {
  const PickableOrderCard({
    required this.order,
    required this.picked,
    required this.blockedBecause,
    required this.onToggle,
    super.key,
  });

  final Order order;
  final bool picked;

  /// Null when the card may be picked; otherwise the sentence the tap shows.
  final String? blockedBecause;

  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final blocked = blockedBecause != null && !picked;

    return Opacity(
      opacity: blocked ? 0.45 : 1,
      child: Stack(
        children: [
          DecoratedBox(
            // The border sits outside the card's own, so a picked card is told apart without
            // repainting anything the card itself draws.
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: picked ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: OrderCard(
              order: order,
              onTap: blocked ? () => context.showInfo(blockedBecause!) : onToggle,
            ),
          ),
          PositionedDirectional(
            top: 10.h,
            end: 10.w,
            child: IgnorePointer(
              child: Icon(
                picked ? AppIcons.picked : AppIcons.unpicked,
                size: 24.sp,
                color: picked ? scheme.primary : scheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bar under the list while picking: how many, and the one action it leads to.
///
/// **Two at least**, because one order is what «إرسال للنورس» on the order's own screen is for,
/// and the server refuses a shared parcel of one.
class SendTogetherBar extends StatelessWidget {
  const SendTogetherBar({
    required this.count,
    required this.isSending,
    required this.onSend,
    required this.onCancel,
    super.key,
  });

  final int count;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  count == 0
                      ? 'اختر طلبيتين أو أكثر لزبون واحد'
                      : 'المختار: ${count.grouped}',
                  style: context.textTheme.bodyMedium,
                ),
              ),
              AppButton.outlined(
                label: 'إلغاء',
                expands: false,
                onPressed: isSending ? null : onCancel,
              ),
              SizedBox(width: 8.w),
              AppButton(
                label: 'إرسال معاً للنورس',
                icon: AppIcons.sharedParcel,
                expands: false,
                isLoading: isSending,
                onPressed: count >= 2 ? onSend : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
