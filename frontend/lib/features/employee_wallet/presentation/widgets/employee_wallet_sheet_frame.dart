import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// إطار ورقة المحفظة: مقبضها وعنوانها، وتمرّ فوق لوحة المفاتيح — على شكل ورقة «شحن المحفظة».
class EmployeeWalletSheetFrame extends StatelessWidget {
  const EmployeeWalletSheetFrame({
    required this.title,
    required this.formKey,
    required this.children,
    this.titleAction,
    super.key,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  /// في آخر سطر العنوان — زرُّ ⓘ مثلاً.
  final Widget? titleAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    ?titleAction,
                  ],
                ),
                SizedBox(height: 20.h),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
