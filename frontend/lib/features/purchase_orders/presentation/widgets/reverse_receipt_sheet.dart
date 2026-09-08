import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Undoing a receipt entered in error — «التراجع عن الاستلام».
///
/// **The sheet sends the request itself, unlike every other sheet in this feature.** The receive
/// sheet collects a shipment and hands it back for the screen to post, because there is nothing
/// useful to say about a refusal beyond «try again». Here there is: each refusal names a
/// different problem and most of them tell the person to do something else instead — a stocktake
/// adjustment rather than a reversal. That sentence has to arrive **in front of the person who
/// is still mid-decision**, not on a snackbar behind a sheet that has already closed. So the
/// sheet stays open until the server says yes, and prints the refusal above its own button.
///
/// **It says what will happen before it asks.** This takes real stock off a real shelf and
/// reopens paperwork somebody already closed; «هل أنت متأكد؟» is not enough to authorise that.
///
/// Returns `true` once the reversal went through, and null when the person backed out.
Future<bool?> showReverseReceiptSheet({
  required BuildContext context,
  required PurchaseOrder order,
  required Future<Failure?> Function(String reason) onConfirm,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Off, deliberately: a tap outside is how a sheet is dismissed by accident, and this one is
    // holding a typed reason and — after a refusal — the only copy of the server's explanation.
    isDismissible: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _ReverseReceiptSheet(order: order, onConfirm: onConfirm),
  );
}

class _ReverseReceiptSheet extends StatefulWidget {
  const _ReverseReceiptSheet({required this.order, required this.onConfirm});

  final PurchaseOrder order;
  final Future<Failure?> Function(String reason) onConfirm;

  @override
  State<_ReverseReceiptSheet> createState() => _ReverseReceiptSheetState();
}

class _ReverseReceiptSheetState extends State<_ReverseReceiptSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  bool _isSending = false;

  /// The server's own sentence from the last refusal, kept on screen until the next attempt.
  Failure? _failure;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSending) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSending = true;
      // Cleared as the next attempt starts: leaving the old refusal up while a new one is in
      // flight makes a request that succeeds look like it failed.
      _failure = null;
    });

    final failure = await widget.onConfirm(_reason.text.trim());

    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _isSending = false;
        _failure = failure;
      });

      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'التراجع عن الاستلام',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'أمر شراء #${widget.order.id} · ${widget.order.vendorName}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 20.h),

                const _WhatWillHappen(),
                SizedBox(height: 20.h),

                AppTextField(
                  key: const Key('reverse-receipt-reason'),
                  controller: _reason,
                  label: 'سبب التراجع',
                  hint: 'سُجّلت الكمية خطأً — ٥٠٠ بدل ٥٠',
                  prefixIcon: AppIcons.edit,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  validator: _validateReason,
                ),

                // The refusal, in the server's own words and unedited — see the note on the
                // function above for why it lands here rather than on a snackbar.
                if (_failure case final failure?) ...[
                  SizedBox(height: 16.h),
                  _Refusal(failure: failure),
                ],

                SizedBox(height: 24.h),
                AppButton(
                  key: const Key('reverse-receipt-confirm'),
                  label: 'التراجع عن الاستلام',
                  icon: AppIcons.undo,
                  isLoading: _isSending,
                  onPressed: _submit,
                ),
                SizedBox(height: 8.h),
                AppButton.outlined(
                  label: 'تراجع',
                  // Null rather than a no-op while the request is in flight: closing the sheet
                  // now would leave the person with no idea whether the stock came off the
                  // shelf or not.
                  onPressed: _isSending
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The API's own three characters, one round trip earlier.
  ///
  /// **Client-side because the server's answer would tell the person nothing they could not have
  /// been told by the box itself** — and a round trip to learn that a reason is required is a
  /// round trip spent on a rule that never changes.
  String? _validateReason(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'سبب التراجع مطلوب';
    if (text.length < 3) return 'سبب التراجع قصير جداً';
    if (text.length > 500) return 'سبب التراجع طويل جداً';

    return null;
  }
}

/// What the button is about to do, in plain words.
///
/// Three sentences and no arithmetic: unlike the revaluation sheet, nothing here depends on what
/// has been typed — the consequences of undoing a receipt are the same every time, and they are
/// exactly the part people do not expect.
class _WhatWillHappen extends StatelessWidget {
  const _WhatWillHappen();

  static const List<String> _lines = [
    'سيُسحب ما استُلم من الرف، وترجع أرصدة المخزن إلى ما كانت عليه قبل الشحنة',
    'يعود الأمر إلى «قيد الاستلام» ليُسجَّل الاستلام من جديد بالكميات الصحيحة',
    'تبقى الشحنة في السجل مؤشَّراً عليها بأنها مُلغاة — لا تُحذف',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, line) in _lines.indexed) ...[
            if (index > 0) SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.undo, size: 16.sp, color: scheme.warn),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    line,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Why the server said no, as it said it.
///
/// **Never re-worded.** «صُرف من الدفعة… الصواب تسوية جرد لا إلغاء استلام» is not a generic
/// failure — it is an instruction to do something else, and the app has no better sentence for
/// any of the five refusals this endpoint sends.
class _Refusal extends StatelessWidget {
  const _Refusal({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      key: const Key('reverse-receipt-refusal'),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.error, size: 16.sp, color: scheme.onErrorContainer),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  failure.message,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (failure.details case final details?) ...[
                  SizedBox(height: 4.h),
                  Text(
                    details,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
