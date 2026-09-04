import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مستثمر جديد', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'الاسم'),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value ?? '').trim().length < 2 ? 'اسم المستثمر مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'الهاتف (اختياري)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            // Full width with small margins — the standing rule for an action button.
            AppButton(label: 'حفظ', isLoading: _saving, onPressed: _saving ? null : _submit),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
