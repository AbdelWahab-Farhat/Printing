import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «المدفوع للمورد» on a purchase order — the total, what was paid against it, and what is still
/// owed, with every payment beneath and «دفعة للمورد» to add one. TREASURY-DESIGN §٨.
///
/// **Its own request, its own grant.** The order screen draws without it for anybody lacking
/// `vendors.payments.view`, and a failed load leaves the rest of the order standing.
class PurchaseOrderPaymentsSection extends StatefulWidget {
  const PurchaseOrderPaymentsSection({
    required this.purchaseOrderId,
    required this.vendorId,
    super.key,
  });

  final int purchaseOrderId;
  final int vendorId;

  @override
  State<PurchaseOrderPaymentsSection> createState() => _PurchaseOrderPaymentsSectionState();
}

class _PurchaseOrderPaymentsSectionState extends State<PurchaseOrderPaymentsSection> {
  PurchaseOrderPayments? _payments;

  bool get _canView =>
      sl.isRegistered<Session>() && sl<Session>().can(AppPermission.viewVendorPayments);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!_canView || !sl.isRegistered<GetPurchaseOrderPayments>()) return;

    final result = await sl<GetPurchaseOrderPayments>()(widget.purchaseOrderId);

    if (!mounted) return;

    result.fold((_) {}, (payments) => setState(() => _payments = payments));
  }

  Future<void> _pay() async {
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PayVendorForm(
        vendorId: widget.vendorId,
        purchaseOrderId: widget.purchaseOrderId,
        suggested: _payments?.payableUpTo ?? _payments?.remaining,
      ),
    );

    if (paid ?? false) unawaited(_load());
  }

  /// «خصم من المورد» — the vendor sent short or gave a discount. No drawer is touched.
  Future<void> _credit() async {
    final credited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreditVendorForm(
        vendorId: widget.vendorId,
        purchaseOrderId: widget.purchaseOrderId,
      ),
    );

    if (credited ?? false) unawaited(_load());
  }

  /// «يُحسب عليه دين للمورد» — this old order is still owed. One way, so it asks first.
  Future<void> _countAsDebt(PurchaseOrderPayments payments) async {
    final confirmed = await showCustomDialog(
      context: context,
      title: 'يُحسب عليه دين للمورد',
      description:
          'يُضاف إجمالي الأمر (${treasuryMoney(payments.total ?? '0')}) إلى «علينا» للمورد، '
          'ويُخصم منه ما دُفع عليه منذ النظام (${treasuryMoney(payments.paid)}). '
          'استعمله لأمرٍ ما زال مستحقاً فقط — لا يُتراجع عنه.',
      confirmLabel: 'احسبه ديناً',
      severity: DialogSeverity.warning,
      barrierDismissible: false,
    );

    if (!(confirmed ?? false) || !mounted) return;

    final result = await sl<CountOldOrderAsDebt>()(widget.purchaseOrderId);

    if (!mounted) return;

    result.fold((failure) => context.showError(failure.message, details: failure.details), (_) {
      context.showSuccess('حُسب دين الأمر على المورد');
      unawaited(_load());
    });
  }

  Future<void> _reverse(VendorPayment payment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(),
    );

    if (reason == null || !mounted) return;

    final result = await sl<ReverseVendorPayment>()(
      vendorId: widget.vendorId,
      paymentId: payment.id,
      reason: reason,
    );

    if (!mounted) return;

    result.fold((failure) => context.showError(failure.message, details: failure.details), (_) {
      context.showSuccess('تم عكس الدفعة');
      unawaited(_load());
    });
  }

  @override
  Widget build(BuildContext context) {
    final payments = _payments;

    if (payments == null) return const SizedBox.shrink();

    final session = sl<Session>();
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TreasuryFiguresCard(
            title: 'المدفوع للمورد',
            icon: AppIcons.payment,
            lines: [
              if (payments.total case final total?) ('إجمالي الأمر', total),
              ('المدفوع', payments.paid),
              if (payments.credited != '0.00') ('خصم من المورد', payments.credited),
            ],
            emphasis: payments.remaining == null ? null : ('المتبقي للمورد', payments.remaining!),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: _footer(context, payments, session, scheme),
          ),
        ],
      ),
    );
  }

  Widget _footer(
    BuildContext context,
    PurchaseOrderPayments payments,
    Session session,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (payments.predatesTreasury)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              // Payable all the same, up to its total less what was paid on it since (§٢٠).
              (payments.payableUpTo ?? '0.00') != '0.00'
                  ? 'أمرٌ سابق لنظام الحسابات — يُدفع عليه حتى '
                        '${treasuryMoney(payments.payableUpTo!)}، ولا يُحسب على «علينا»'
                  : 'أمرٌ سابق لنظام الحسابات — لا يُحسب عليه متبقٍّ',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        for (final payment in payments.payments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${payment.typeLabel} · ${treasuryMoney(payment.amount)}',
              style: payment.isReversed
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: Text(
              [
                ?payment.methodLabel,
                ?payment.accountName,
                if (payment.paidAt case final at?) at.timeLabel,
                ?payment.recorderName,
              ].join(' · '),
            ),
            trailing: payment.isReversible && session.can(AppPermission.reverseVendorPayments)
                ? IconButton(
                    tooltip: 'عكس الدفعة',
                    icon: Icon(AppIcons.reversePayment),
                    onPressed: () => _reverse(payment),
                  )
                : null,
          ),
        if (session.can(AppPermission.recordVendorPayments)) ...[
          SizedBox(height: 8.h),
          AppButton.tonal(label: 'دفعة للمورد', icon: AppIcons.payment, onPressed: _pay),
          // An old order still owed is brought onto «علينا» by hand — the system cannot tell
          // which of them were paid before it existed (§٢٠).
          if (payments.predatesTreasury && payments.total != null) ...[
            SizedBox(height: 8.h),
            AppButton.tonal(
              label: 'يُحسب عليه دين للمورد',
              icon: AppIcons.payable,
              onPressed: () => _countAsDebt(payments),
            ),
          ],
          // Nothing is paid or credited in advance (§٢٠), so neither is offered once the order
          // owes nothing — the server would refuse it anyway.
          if (payments.remaining != null && payments.remaining != '0.00') ...[
            SizedBox(height: 8.h),
            AppButton.tonal(label: 'خصم من المورد', icon: AppIcons.expense, onPressed: _credit),
          ],
        ],
      ],
    );
  }
}

/// «خصم من المورد» — what the vendor knocked off: a short delivery, a discount. It lowers what is
/// owed on the order and moves no money; the server refuses more than is left on it.
class _CreditVendorForm extends StatefulWidget {
  const _CreditVendorForm({required this.vendorId, required this.purchaseOrderId});

  final int vendorId;
  final int purchaseOrderId;

  @override
  State<_CreditVendorForm> createState() => _CreditVendorFormState();
}

class _CreditVendorFormState extends State<_CreditVendorForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final notes = _notes.text.trim();

    final result = await sl<CreditVendor>()(
      vendorId: widget.vendorId,
      purchaseOrderId: widget.purchaseOrderId,
      amount: Validators.toWesternDigits(_amount.text.trim()),
      notes: notes.isEmpty ? null : notes,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    result.fold((failure) => context.showError(failure.message, details: failure.details), (_) {
      Navigator.of(context).pop(true);
      context.showSuccess('تم تسجيل الخصم');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: context.keyboardInset + 16.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'خصم من المورد',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6.h),
              Text(
                'نقصٌ في الشحنة أو تخفيض — يُنقص المستحق للمورد ولا يحرّك مالاً',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 20.h),
              AppTextField(
                controller: _amount,
                label: 'المبلغ',
                prefixIcon: AppIcons.payment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                validator: (value) {
                  final amount = double.tryParse(Validators.toWesternDigits((value ?? '').trim()));

                  return amount == null || amount <= 0 ? 'المبلغ يجب أن يكون أكبر من صفر' : null;
                },
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: _notes,
                label: 'السبب (اختياري)',
                prefixIcon: AppIcons.notes,
                maxLines: 2,
              ),
              SizedBox(height: 24.h),
              AppButton(
                label: 'تسجيل الخصم',
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «دفعة للمورد» — how much, how, and from which drawer. The drawer must hold it: the server
/// refuses a payment the account cannot cover, and says so under the amount.
class _PayVendorForm extends StatefulWidget {
  const _PayVendorForm({required this.vendorId, required this.purchaseOrderId, this.suggested});

  final int vendorId;
  final int purchaseOrderId;
  final String? suggested;

  @override
  State<_PayVendorForm> createState() => _PayVendorFormState();
}

class _PayVendorFormState extends State<_PayVendorForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: (widget.suggested ?? '').startsWith('-') || widget.suggested == '0.00'
        ? ''
        : widget.suggested ?? '',
  );
  final _reference = TextEditingController();
  final _notes = TextEditingController();

  PaymentMethod _method = PaymentMethod.bankTransfer;
  int? _accountId;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final reference = _reference.text.trim();
    final notes = _notes.text.trim();

    final result = await sl<PayVendor>()(
      vendorId: widget.vendorId,
      purchaseOrderId: widget.purchaseOrderId,
      amount: Validators.toWesternDigits(_amount.text.trim()),
      method: _method.wire,
      accountId: _accountId,
      reference: reference.isEmpty ? null : reference,
      notes: notes.isEmpty ? null : notes,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    result.fold((failure) => context.showError(failure.message, details: failure.details), (_) {
      Navigator.of(context).pop(true);
      context.showSuccess('تم تسجيل الدفعة');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: context.keyboardInset + 16.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'دفعة للمورد',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 20.h),
              AppTextField(
                controller: _amount,
                label: 'المبلغ',
                prefixIcon: AppIcons.payment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                validator: (value) {
                  final amount = double.tryParse(Validators.toWesternDigits((value ?? '').trim()));

                  return amount == null || amount <= 0 ? 'المبلغ يجب أن يكون أكبر من صفر' : null;
                },
              ),
              SizedBox(height: 16.h),
              AppDropdown<PaymentMethod>(
                value: _method,
                items: PaymentMethod.selectable,
                labelOf: (method) => method.label,
                label: 'طريقة الدفع',
                prefixIcon: AppIcons.payment,
                onChanged: (method) {
                  if (method == null) return;

                  setState(() {
                    _method = method;
                    _accountId = null;
                  });
                },
              ),
              SizedBox(height: 16.h),
              TreasuryAccountPicker(
                method: _method.wire,
                incoming: false,
                value: _accountId,
                onChanged: (id) => setState(() => _accountId = id),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: _reference,
                label: 'رقم المرجع (اختياري)',
                prefixIcon: AppIcons.tag,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: _notes,
                label: 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                maxLines: 2,
              ),
              SizedBox(height: 24.h),
              AppButton(
                label: 'تسجيل الدفعة',
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('عكس الدفعة'),
      content: TextField(
        controller: _reason,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'السبب'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            final text = _reason.text.trim();

            if (text.isNotEmpty) Navigator.of(context).pop(text);
          },
          child: const Text('عكس'),
        ),
      ],
    );
  }
}
