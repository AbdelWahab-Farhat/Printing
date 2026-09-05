import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Adds a person whose money we are about to hold.
///
/// Name only is enough: a phone is useful and a code is the server's to allocate. Nothing about
/// his money is asked here — that is recorded against him afterwards, one movement at a time.
Future<bool?> showInvestorFormSheet({required BuildContext context}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _InvestorForm(),
  );
}

class _InvestorForm extends StatefulWidget {
  const _InvestorForm();

  @override
  State<_InvestorForm> createState() => _InvestorFormState();
}

class _InvestorFormState extends State<_InvestorForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final result = await sl<CreateInvestor>()(
      name: _name.text,
      phone: _phone.text,
      notes: _notes.text,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    result.fold(
      (failure) => context.showError(failure.message),
      (_) {
        Navigator.of(context).pop(true);
        context.showSuccess('تم إضافة المستثمر');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: context.keyboardInset + 16.h,
      ),
      child: SingleChildScrollView(
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
                'مستثمر جديد',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 20.h),

              AppTextField(
                controller: _name,
                label: 'الاسم',
                prefixIcon: AppIcons.person,
                validator: Validators.minLength(2, label: 'اسم المستثمر'),
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _phone,
                label: 'رقم الهاتف (اختياري)',
                prefixIcon: AppIcons.phone,
                keyboardType: TextInputType.phone,
                // A Latin run inside a right-to-left form: `0912345678` reads backwards without
                // this.
                textDirection: TextDirection.ltr,
                // Deliberately not [Validators.libyanPhone]: an investor is not a member of
                // staff signing in, and a partner reachable on a foreign number is somebody this
                // form must not refuse. The server takes any string here for the same reason.
                validator: Validators.optional(Validators.contactPhone),
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _notes,
                label: 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                textInputAction: TextInputAction.done,
                maxLines: 2,
              ),
              SizedBox(height: 24.h),

              // Full width with small margins — the standing rule for an action button.
              AppButton(label: 'حفظ', isLoading: _saving, onPressed: _saving ? null : _submit),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
