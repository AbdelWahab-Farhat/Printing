import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:flutter/material.dart';

/// The four movements a person may record against an investor's money.
///
/// **`profit` and `loss` are deliberately absent.** An earning is written by the order that
/// produced it, and offering it on a form would be offering somebody the chance to invent one —
/// after which the deal screen and the orders behind it would say two different things.
enum WalletAction {
  deposit('deposit', 'إيداع رأس مال', 'مال يسلّمه لنا'),
  allocation('allocation', 'تمويل صفقة', 'من رصيد محفظته إلى صفقة'),
  withdrawal('withdrawal', 'سحب رأس مال', 'من رصيد محفظته'),
  profitWithdrawal('profit_withdrawal', 'سحب أرباح', 'من الأرباح المتاحة بعد إقفال صفقة');

  const WalletAction(this.wire, this.label, this.caption);

  final String wire;
  final String label;
  final String caption;

  bool get needsDeal => this == WalletAction.allocation;

  bool get needsMethod => this != WalletAction.allocation;
}

Future<void> showWalletEntrySheet({
  required BuildContext context,
  required InvestorDetailCubit cubit,
  required Investor investor,
  required List<({int id, String label})> deals,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _WalletEntryForm(cubit: cubit, investor: investor, deals: deals),
  );
}

class _WalletEntryForm extends StatefulWidget {
  const _WalletEntryForm({
    required this.cubit,
    required this.investor,
    required this.deals,
  });

  final InvestorDetailCubit cubit;
  final Investor investor;
  final List<({int id, String label})> deals;

  @override
  State<_WalletEntryForm> createState() => _WalletEntryFormState();
}

class _WalletEntryFormState extends State<_WalletEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  WalletAction _action = WalletAction.deposit;
  String _method = 'cash';
  int? _dealId;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_action.needsDeal && _dealId == null) {
      context.showError('اختر الصفقة');

      return;
    }

    setState(() => _saving = true);

    final failure = await widget.cubit.record(
      investorId: widget.investor.id,
      type: _action.wire,
      amount: _amount.text.trim(),
      investorDealId: _action.needsDeal ? _dealId : null,
      method: _action.needsMethod ? _method : null,
      notes: _notes.text,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure != null) {
      // The server's own words. It refuses a withdrawal above the balance and a payout of profit
      // a running deal has not released, and its message says which — restating either rule here
      // would be a second copy to keep in step.
      context.showError(failure.message);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess('تم تسجيل الحركة');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('حركة مالية', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<WalletAction>(
                initialValue: _action,
                decoration: const InputDecoration(labelText: 'نوع الحركة'),
                items: WalletAction.values
                    .map(
                      (action) => DropdownMenuItem<WalletAction>(
                        value: action,
                        child: Text(action.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _action = value ?? _action),
              ),
              const SizedBox(height: 4),
              Text(
                _action.caption,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (_action.needsDeal)
                DropdownButtonFormField<int>(
                  initialValue: _dealId,
                  decoration: const InputDecoration(labelText: 'الصفقة'),
                  items: widget.deals
                      .map(
                        (deal) =>
                            DropdownMenuItem<int>(value: deal.id, child: Text(deal.label)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _dealId = value),
                ),
              if (_action.needsMethod)
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                  items: const [
                    DropdownMenuItem<String>(value: 'cash', child: Text('نقداً')),
                    DropdownMenuItem<String>(value: 'bank_transfer', child: Text('حوالة مصرفية')),
                    DropdownMenuItem<String>(value: 'bank_card', child: Text('بطاقة مصرفية')),
                  ],
                  onChanged: (value) => setState(() => _method = value ?? _method),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                decoration: const InputDecoration(labelText: 'المبلغ (د.ل)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final text = (value ?? '').trim();
                  final amount = double.tryParse(text);

                  return amount == null || amount <= 0 ? 'أدخل مبلغاً أكبر من صفر' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              AppButton(label: 'تسجيل', isLoading: _saving, onPressed: _saving ? null : _submit),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
