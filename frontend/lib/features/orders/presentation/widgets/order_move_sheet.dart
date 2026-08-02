import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/orders/models/order.dart';

/// The answer a move sheet returns.
///
/// A wrapper rather than a bare `String?`, because "cancelled" and "confirmed with no reason"
/// are different answers and both would be null. Dismissing returns null; confirming returns
/// this, with [value] null when the move needed no sentence.
@immutable
class OrderMoveConfirmation {
  const OrderMoveConfirmation(this.value);

  final String? value;
}

/// Confirms a status change, asking for a reason when the server says one is owed.
///
/// **`requiresReason` comes from the server**, on the transition itself. So the day a status
/// other than cancellation starts demanding an explanation, this sheet asks for it with no
/// change here — and the 422 the backend would otherwise return is a case the user never meets.
///
/// A bottom sheet rather than a dialog: it needs a text field for some moves, and a dialog that
/// grows a field is a dialog that jumps when the keyboard opens.
Future<OrderMoveConfirmation?> showOrderMoveSheet({
  required BuildContext context,
  required OrderTransition transition,
}) {
  return showModalBottomSheet<OrderMoveConfirmation>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _MoveSheet(transition: transition),
  );
}

class _MoveSheet extends StatefulWidget {
  const _MoveSheet({required this.transition});

  final OrderTransition transition;

  @override
  State<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends State<_MoveSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (widget.transition.requiresReason && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final text = _controller.text.trim();
    Navigator.of(context).pop(OrderMoveConfirmation(text.isEmpty ? null : text));
  }

  @override
  Widget build(BuildContext context) {
    final transition = widget.transition;

    return Padding(
      // Lifts the sheet clear of the keyboard rather than letting it cover the field.
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نقل الطلبية إلى «${transition.label}»',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  transition.requiresReason
                      ? 'هذا الإجراء يتطلب ذكر السبب، ويُسجَّل في سجل الطلبية.'
                      : 'سيُسجَّل هذا الانتقال في سجل الطلبية.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _controller,
                  label: transition.requiresReason ? 'السبب' : 'ملاحظة (اختياري)',
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  validator: transition.requiresReason
                      ? (value) => (value == null || value.trim().isEmpty)
                            ? 'السبب مطلوب'
                            : null
                      : null,
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outlined(
                        label: 'إلغاء',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppButton(label: 'تأكيد', onPressed: _confirm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
