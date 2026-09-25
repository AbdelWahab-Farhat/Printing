import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/number_input_formatters.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ورقةٌ صغيرة تُكتب فيها كميةٌ بعينها — ما يفتحه الرقم الكبير فوق السلايدر.
///
/// **الكتابة هنا لا في الرقم نفسه.** الرقم في وسط الصفحة فوق السلايدر، وحقلٌ نصّه في الوسط هو
/// ما رُفض في هذا التطبيق من قبل؛ فالرقم يبقى رقماً، والكتابة في حقل التطبيق المعتاد: يبدأ من
/// حافته، والوحدة في طرفه.
///
/// تُرجع ما كُتب حين يُضغط «تم» — كميةً صحيحة فقط — وnull إن أُغلقت الورقة بلا «تم».
Future<String?> showQuantitySheet(
  BuildContext context, {
  required String initial,
  required String? unitLabel,
  required bool wholeOnly,
}) {
  return showModalBottomSheet<String>(
    context: context,
    // كي ترتفع الورقة فوق لوحة المفاتيح بدل أن تختفي تحتها.
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (context) =>
        _QuantitySheet(initial: initial, unitLabel: unitLabel, wholeOnly: wholeOnly),
  );
}

class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({
    required this.initial,
    required this.unitLabel,
    required this.wholeOnly,
  });

  final String initial;
  final String? unitLabel;
  final bool wholeOnly;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  // الكمية الحالية محدّدةٌ كلها، فأول رقمٍ يُكتب يحلّ محلّها ولا يُلصق بها.
  late final _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initial.length);

  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    final typed = _controller.text;

    if (!isOrderableQuantity(typed)) {
      setState(() => _error = 'أدخل كمية صحيحة');

      return;
    }

    Navigator.of(context).pop(typed);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unit = widget.unitLabel;

    return Padding(
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'الكمية',
                style: context.textTheme.titleMedium?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(decimal: !widget.wholeOnly),
                textInputAction: TextInputAction.done,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, height: 1.2),
                inputFormatters: [
                  const WesternDigitsInputFormatter(),
                  QuantityInputFormatter(wholeOnly: widget.wholeOnly),
                ],
                errorText: _error,
                suffix: unit == null
                    ? null
                    : Center(
                        widthFactor: 1,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(end: 14.w),
                          child: Text(
                            unit,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _done(),
              ),
              SizedBox(height: 16.h),
              AppButton(label: 'تم', lifted: false, onPressed: _done),
            ],
          ),
        ),
      ),
    );
  }
}
