import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_sheet_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// سببُ إلغاء الحركة — إجباريٌّ، ويعود مقصوصاً، أو null لمن تراجع.
///
/// **ورقةٌ لا حوار**، كما طلب صاحب العمل لكل ما يأخذ مدخلاً (٢٠٢٦-١٠-١٧). ثلاثة أحرف لا «غير
/// فارغ»: «خطأ» جواب، وحرفٌ شارد ليس جواباً.
Future<String?> askForReversalReason(BuildContext context, {required String title}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReverseSheet(title: title),
  );
}

/// **ويدجت يملك متحكّمه**: الورقة ما زالت تنزل ويقرؤه الإطار بعد أن تعود.
class _ReverseSheet extends StatefulWidget {
  const _ReverseSheet({required this.title});

  final String title;

  @override
  State<_ReverseSheet> createState() => _ReverseSheetState();
}

class _ReverseSheetState extends State<_ReverseSheet> {
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
    return EmployeeWalletSheetFrame(
      title: widget.title,
      formKey: _formKey,
      children: [
        AppTextField(
          controller: _reason,
          label: 'السبب',
          prefixIcon: AppIcons.notes,
          autofocus: true,
          maxLines: 2,
          textInputAction: TextInputAction.newline,
          validator: (value) => (value ?? '').trim().length < 3 ? 'السبب مطلوب' : null,
        ),
        SizedBox(height: 24.h),
        AppButton(label: 'إلغاء الحركة', icon: AppIcons.reversePayment, onPressed: _submit),
        SizedBox(height: 8.h),
        AppButton.outlined(label: 'رجوع', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
