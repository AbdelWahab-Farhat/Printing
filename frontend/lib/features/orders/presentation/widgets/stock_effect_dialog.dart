import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/models/stock_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Asks before archiving an order or bringing it back, and says what it will do to the
/// warehouse **in the server's words**.
///
/// **Not one sentence of the body is written here, and that is the whole design of §٧.** The
/// headline, every line's label, its quantity, its unit and the closing note all arrive on the
/// order as `stock_effect`; this widget lays them out and nothing more. The precedent is
/// `TransitionFields::deductionPreview()`, whose comment gives the two reasons: it reaches every
/// installed build without a release, and it cannot drift from what the action will do, because
/// the preview and the action read the same `OrderItem::producedQuantity()`. A `switch (kind)`
/// here turning a code into Arabic would give up both.
///
/// **A bespoke dialog rather than `showDestructiveDialog`**, for the reason
/// `reinstate_order_dialog.dart` is one: there is a *list* in the middle of the body. The shared
/// dialog takes a single centred paragraph, and «كيس شحن 25*35 — 300 قطعة» folded into a
/// sentence is exactly the thing somebody needs to read down, item by item, before agreeing to
/// move it.
///
/// **The list is the loud part, not the title.** Whether the goods come back or go out again is
/// what the reader is being asked about, so the lines sit in the error container the way the
/// reinstate dialog's own warning does — and on a [StockEffectKind.none] there is no panel at
/// all, because a red box around «لا يتحرّك شيء» is a warning about nothing.
///
/// Returns `true` when confirmed and null otherwise — the same three-way answer
/// `showCustomDialog` gives, for the same reason: walking out of a destructive dialog is not
/// «no», it is «not now».
Future<bool?> showStockEffectDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  required StockEffect effect,
  required bool destructive,
}) {
  return showDialog<bool>(
    context: context,
    // Off for the reason `showDestructiveDialog` turns it off: both of these move stock, and a
    // stray tap outside should not be one of the two ways to say yes.
    barrierDismissible: false,
    builder: (_) => _StockEffectDialog(
      title: title,
      confirmLabel: confirmLabel,
      effect: effect,
      destructive: destructive,
    ),
  );
}

class _StockEffectDialog extends StatelessWidget {
  const _StockEffectDialog({
    required this.title,
    required this.confirmLabel,
    required this.effect,
    required this.destructive,
  });

  final String title;
  final String confirmLabel;
  final StockEffect effect;

  /// Whether the confirm button is drawn in the error colour. True for «حذف» and false for
  /// «استعادة» — one takes the order out of the shop, and the other is the way back.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The headline, always — including on a preview that moves nothing, where it is the
            // whole answer. A dialog that showed an empty body would read as one that failed to
            // load rather than as «لا شيء يتحرّك».
            Text(
              effect.warning,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),

            if (effect.lines.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in effect.lines)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Row(
                          children: [
                            // The name takes what is left, and the figure keeps its place at the
                            // end of the row: a reader scanning a delete is counting, and a
                            // column of quantities that moved with each label is not a column.
                            Expanded(
                              child: Text(
                                line.label,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onErrorContainer,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // The unit beside the number and never mapped from a code here:
                            // «قطعة» and «كجم» are the server's, exactly as the label is.
                            Text(
                              '${line.quantity} ${line.unit}',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: scheme.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // The second paragraph, which only the restore carries: the new deduction eats
            // today's cost layers, so the order comes back having cost something else. Under
            // the list rather than in it — it is about all of them at once.
            if (effect.note case final note?) ...[
              SizedBox(height: 12.h),
              Text(
                note,
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive ? TextButton.styleFrom(foregroundColor: scheme.error) : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
