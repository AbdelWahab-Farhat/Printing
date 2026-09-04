import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The note somebody typed beside the undo. Empty when they typed nothing, which is allowed.
typedef ReinstateDraft = ({String? reason});

/// Asks whether an order really was cancelled by mistake, and says what putting it back does
/// **and does not** do.
///
/// **A dialog rather than a screen or a sheet, because there is nothing to choose.** Every other
/// move an order makes goes through «تغيير الحالة», where the destination is picked and the
/// fields it asks for are filled in. This one has no destination — the server reads it off the
/// order's own timeline — and one optional field, so a screen would be a screen with a single
/// button on it.
///
/// **The two sentences in the body are the whole reason it is a dialog and not a bare confirm.**
/// Where the order is going has to be said before the tap, not discovered after it; and the
/// stock has to be said at all, because the cancellation credited the goods back to the shelf
/// and this does not take them out again. Somebody who reinstates an order and assumes the
/// warehouse followed is the one person this dialog exists for.
Future<ReinstateDraft?> showReinstateOrderDialog({
  required BuildContext context,
  required Order order,
}) {
  return showDialog<ReinstateDraft>(
    context: context,
    builder: (_) => _ReinstateOrderDialog(order: order),
  );
}

/// Stateful because it owns a `TextEditingController` — and that ownership is the reason it is a
/// widget rather than a function holding one in a closure. See `write_off_dialog.dart`, which
/// carries the full account of what disposing it beside `showDialog` costs.
class _ReinstateOrderDialog extends StatefulWidget {
  const _ReinstateOrderDialog({required this.order});

  final Order order;

  @override
  State<_ReinstateOrderDialog> createState() => _ReinstateOrderDialogState();
}

class _ReinstateOrderDialogState extends State<_ReinstateOrderDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final typed = _reason.text.trim();

    Navigator.of(context).pop((reason: typed.isEmpty ? null : typed));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    // The server's own Arabic for the status, never mapped from the code here — the same rule
    // `statusLabel` follows, so a status this build has never heard of still reads correctly.
    // It falls back to the wire word only if a server sent the one key without the other.
    final destination = widget.order.reinstateToLabel ?? widget.order.reinstateTo?.label ?? '';

    return AlertDialog(
      title: const Text('تراجع عن الإلغاء'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Where it lands, said before the tap. There is no choice to offer — the server puts
            // the order back exactly where the cancellation took it from.
            Text(
              'ترجع الطلبية إلى «$destination» — الحالة التي أُلغيت منها. '
              'ويبقى الإلغاء وسببه في سجل الطلبية.',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 12.h),

            // **The half nobody would guess**, in the colour that stops it being skimmed. The
            // cancellation put the goods back on the shelf; this does not take them out again.
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'المخزون لا يُخصم من جديد: الكمية رجعت للمخزن عند الإلغاء، وتُخصم يدوياً إن لزم.',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
            SizedBox(height: 16.h),

            AppTextField(
              controller: _reason,
              label: 'السبب (اختياري)',
              maxLines: 2,
              // Optional here and on the server, and deliberately: the cancellation being undone
              // is the move that already had to justify itself, and asking for a second sentence
              // to correct a stray tap stands between somebody and the fix.
              helperText: 'يُسجَّل في سجل الطلبية',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        TextButton(onPressed: _submit, child: const Text('تراجع عن الإلغاء')),
      ],
    );
  }
}
