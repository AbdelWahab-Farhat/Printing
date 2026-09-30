import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Asks for the reason behind «تراجع عن التسوية» or «تراجع عن التسليم», and says what the undo
/// does before the tap. Answers with the trimmed reason, or null when dismissed.
///
/// **One dialog for both**, shaped like `reinstate_order_dialog.dart`: there is no destination
/// to choose — the server fixes it — so a screen would be a screen with a single button. It
/// differs in one rule: **the reason is required**, because each of these reopens something the
/// books treated as closed, so the confirm button stays off until one is typed.
Future<String?> showUndoOrderStepDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String warning,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _UndoOrderStepDialog(title: title, body: body, warning: warning),
  );
}

/// Stateful because it owns its `TextEditingController` — disposed here, never after
/// `showDialog` returns, while the exit animation is still reading it.
class _UndoOrderStepDialog extends StatefulWidget {
  const _UndoOrderStepDialog({required this.title, required this.body, required this.warning});

  final String title;
  final String body;
  final String warning;

  @override
  State<_UndoOrderStepDialog> createState() => _UndoOrderStepDialogState();
}

class _UndoOrderStepDialogState extends State<_UndoOrderStepDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.body,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 12.h),

            // What happens to the money, in the colour that stops it being skimmed.
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                widget.warning,
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
            SizedBox(height: 16.h),

            AppTextField(
              controller: _reason,
              label: 'السبب',
              maxLines: 2,
              helperText: 'مطلوب — يُسجَّل في سجل الطلبية',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _reason,
          builder: (context, value, _) {
            final typed = value.text.trim();

            return TextButton(
              onPressed: typed.isEmpty ? null : () => Navigator.of(context).pop(typed),
              child: Text(widget.title),
            );
          },
        ),
      ],
    );
  }
}
