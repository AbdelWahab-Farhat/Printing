import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/shortages/models/shortage_supply.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «عكس عملية التوفير» — and the sentence that has to go beside it.
///
/// **The reason is required by the server, so it is asked for here.** A correction to a money
/// ledger is read months later by somebody working out what happened, and «عُكست» with nothing
/// beside it answers nothing — the same rule an order payment's cancellation follows, and the
/// dialog is shaped after that one on purpose.
///
/// **What the reversal does and does not do is spelled out before the button**, because the two
/// halves surprise people in opposite directions: the goods really do come back off the shelf,
/// and the customer's invoice really is left alone. A reversal here means *this entry was wrong*
/// — typed twice, wrong shortage, wrong amount — not that sacks were returned.
///
/// A `StatefulWidget` rather than a controller created beside `showDialog` and disposed in
/// `.whenComplete()`: that fires the moment the route pops, while the dialog is still fading out
/// and its field can still be rebuilt. A `State` disposes after the element leaves the tree,
/// which is the only ordering that is safe by construction — the order payments screen carries
/// the same note, having been caught by exactly that.
Future<String?> showReverseSupplyDialog({
  required BuildContext context,
  required ShortageSupply supply,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReverseSupplyDialog(supply: supply),
  );
}

class _ReverseSupplyDialog extends StatefulWidget {
  const _ReverseSupplyDialog({required this.supply});

  final ShortageSupply supply;

  @override
  State<_ReverseSupplyDialog> createState() => _ReverseSupplyDialogState();
}

class _ReverseSupplyDialogState extends State<_ReverseSupplyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(_reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final supply = widget.supply;

    return AlertDialog(
      title: const Text('عكس عملية التوفير'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Said out loud because both halves surprise people, in opposite directions.
            if (supply.movedStock) ...[
              SizedBox(height: 8.h),
              Text(
                'تخرج البضاعة من المخزن — وقد يرفض المخزون ذلك إن كانت الطبقة قد سُحبت.',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],

            SizedBox(height: 16.h),
            AppTextField(
              controller: _reason,
              label: 'السبب',
              autofocus: true,
              maxLines: 2,
              // Three characters rather than «not empty», the same floor the payment dialog
              // uses: «خطأ» is an answer, a single stray keystroke is not.
              validator: (value) => (value ?? '').trim().length < 3 ? 'السبب مطلوب' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('تراجع')),
        TextButton(
          onPressed: _submit,
          child: Text('عكس العملية', style: TextStyle(color: scheme.error)),
        ),
      ],
    );
  }
}
