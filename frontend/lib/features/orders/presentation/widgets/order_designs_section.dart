import 'dart:async';

import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_thumbnail.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_viewer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The artwork conversation, version by version — and the three things staff do to it.
///
/// Newest first: the version under discussion is the one staff need, and it is the one the
/// server puts first.
///
/// A rejected version keeps the sentence it was turned down for. That is the reason versions
/// are rows in the first place: «لم يعجبه التصميم» is only useful if it says what about it.
///
/// **Approving is here rather than on the move screen, and that is the point of the split.**
/// Adding a version is not a status change — the order sits in «قيد التصميم» while versions
/// come and go — and approving one is what *unlocks* printing rather than being a step of its
/// own. Both stay available for as long as the order is open, so the artwork can be corrected
/// whenever, without pretending to move the order to do it.
///
/// **Looking at the artwork needs no permission and no callback.** Tapping a version opens the
/// file full screen, and the button beside it saves a copy to the phone — both read the same
/// signed link the row already carries, so anyone who may see the order may see what is being
/// printed on it. Judging one is the part that is gated.
///
/// Every *action* callback is null for somebody without `orders.designs.manage`, and then this
/// section reads.
class OrderDesignsSection extends StatelessWidget {
  const OrderDesignsSection({
    required this.designs,
    this.onAdd,
    this.onApprove,
    this.onReject,
    this.isWorking = false,
    super.key,
  });

  final List<OrderDesign> designs;

  /// Proposes another version. Null when the order is closed or the user may not.
  final Future<void> Function()? onAdd;

  final Future<void> Function(OrderDesign design)? onApprove;

  /// Given the sentence the version was turned down for — the server insists on one.
  final Future<void> Function(OrderDesign design, String reason)? onReject;

  /// Something is in flight. The buttons stop accepting a second tap; nothing else changes,
  /// because everything else on screen is still true.
  final bool isWorking;

  Future<void> _reject(BuildContext context, OrderDesign design) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectionDialog(),
    );

    if (reason == null) return;

    await onReject?.call(design, reason);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (designs.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              'لا توجد نسخة من التصميم بعد',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final design in designs)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: design.isApproved ? scheme.tertiary : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // The artwork itself, and now the way into it: tapping opens the file full
                    // screen. «نسخة ٢» and «نسخة ٣» are the same three characters apart, and
                    // what was approved is a question about what is *on* them — which used to
                    // be unanswerable from this screen without opening the customer's library.
                    if (design.design case final file?) ...[
                      InkWell(
                        onTap: () => unawaited(showDesign(context, file)),
                        borderRadius: BorderRadius.circular(10.r),
                        child: DesignThumbnail(design: file, size: 48),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'نسخة ${design.version}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              design.statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: design.isApproved
                                    ? scheme.tertiary
                                    : design.isRejected
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Saving is one tap from the row, not two from a viewer: the person who
                    // needs the file usually needs to send it to the printer, and never looked
                    // at it on this screen at all.
                    if (design.design case final file?)
                      IconButton(
                        tooltip: 'تحميل',
                        onPressed: () => unawaited(saveDesign(context, file)),
                        icon: Icon(AppIcons.download, color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
                if (design.rejectionReason case final reason?) ...[
                  SizedBox(height: 6.h),
                  Text(
                    reason,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (design.notes case final notes?) ...[
                  SizedBox(height: 4.h),
                  Text(
                    notes,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],

                // A version is judged once — the server refuses a second verdict — so the
                // buttons belong only to the one still waiting for an answer.
                if (!design.isReviewed && (onApprove != null || onReject != null)) ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      if (onApprove != null)
                        Expanded(
                          child: AppButton.tonal(
                            label: 'اعتماد',
                            icon: AppIcons.activate,
                            height: 42.h,
                            onPressed: isWorking ? null : () => onApprove!(design),
                          ),
                        ),
                      if (onApprove != null && onReject != null) SizedBox(width: 10.w),
                      if (onReject != null)
                        Expanded(
                          child: AppButton.outlined(
                            label: 'رفض',
                            icon: AppIcons.close,
                            height: 42.h,
                            onPressed: isWorking ? null : () => _reject(context, design),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        if (onAdd != null) ...[
          SizedBox(height: 4.h),
          AppButton.tonal(
            label: designs.isEmpty ? 'إضافة تصميم' : 'إضافة نسخة',
            icon: AppIcons.designs,
            onPressed: isWorking ? null : onAdd,
          ),
        ],
      ],
    );
  }
}

/// «لماذا رُفض؟» — the sentence a rejection owes.
///
/// The server refuses a rejection without one, so asking here is what turns a 422 into a
/// question, and the answer is what makes the next version worth making.
class _RejectionDialog extends StatefulWidget {
  const _RejectionDialog();

  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رفض التصميم'),
      content: AppTextField(
        controller: _reason,
        label: 'سبب الرفض',
        autofocus: true,
        maxLines: 3,
        maxLength: 1000,
        textInputAction: TextInputAction.newline,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            final reason = _reason.text.trim();
            // Refused here rather than sent: the server answers 422 for an empty one, and a
            // dialog that closes on a refusal is a dialog the user has to reopen.
            if (reason.isEmpty) return;

            Navigator.of(context).pop(reason);
          },
          child: const Text('رفض'),
        ),
      ],
    );
  }
}
