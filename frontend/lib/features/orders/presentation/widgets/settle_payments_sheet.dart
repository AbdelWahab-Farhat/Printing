import 'dart:async';

import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «تسوية دفعة» — one payment or several, carried to the account their money reached.
/// TREASURY-DESIGN §٢٣.
///
/// **One destination for all of them**, «تلقائي» by default: each payment goes where the order's
/// own settlement would have put it — the bank for Nawris's money, the collecting account for
/// «مصرف علي». A payment already in its place has no automatic account, and then one must be
/// named.
///
/// **What the carrier kept, per payment**, only on money a carrier held: Nawris pays the week's
/// parcels less its fees, and «يصل» under the list is the figure to match against its transfer.
///
/// **Stays open on a refusal**, with the server's sentence under the row it names — ten payments
/// typed in are not retyped because one was settled a minute ago by somebody else. Pops `true`
/// once saved.
Future<bool?> showSettlePaymentsSheet({
  required BuildContext context,
  required List<OrderPayment> payments,
  required List<SettlementAccount> destinations,
  required Future<Failure?> Function(List<SettleRow> rows, int? accountId) onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SettlePaymentsSheet(
      payments: payments,
      destinations: destinations,
      onSubmit: onSubmit,
    ),
  );
}

class _SettlePaymentsSheet extends StatefulWidget {
  const _SettlePaymentsSheet({
    required this.payments,
    required this.destinations,
    required this.onSubmit,
  });

  final List<OrderPayment> payments;
  final List<SettlementAccount> destinations;
  final Future<Failure?> Function(List<SettleRow> rows, int? accountId) onSubmit;

  @override
  State<_SettlePaymentsSheet> createState() => _SettlePaymentsSheetState();
}

class _SettlePaymentsSheetState extends State<_SettlePaymentsSheet> {
  final _formKey = GlobalKey<FormState>();

  /// One fee box per payment a carrier held, keyed by the payment.
  late final Map<int, TextEditingController> _fees = {
    for (final payment in widget.payments)
      if (payment.isHeldByCarrier) payment.id: TextEditingController(),
  };

  int? _accountId;
  bool _saving = false;
  Failure? _failure;

  @override
  void dispose() {
    for (final controller in _fees.values) {
      controller.dispose();
    }

    super.dispose();
  }

  /// Whether every payment has somewhere to go when nobody picks.
  bool get _allHaveATarget => widget.payments.every((p) => p.settlementTarget != null);

  /// «تلقائي — المصرف» when they all go to one account, «تلقائي — كلٌّ إلى حسابه» when they part.
  String get _automatic {
    final targets = {for (final p in widget.payments) p.settlementTarget?.name};

    if (targets.length == 1 && targets.first != null) return 'تلقائي — ${targets.first}';

    return 'تلقائي — كلٌّ إلى حسابه';
  }

  int get _totalCents => widget.payments.fold(0, (sum, p) => sum + _cents(p.amount));

  int get _feeCents => _fees.values.fold(0, (sum, c) => sum + _cents(c.text));

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _failure = null;
    });

    final failure = await widget.onSubmit(
      [
        for (final payment in widget.payments)
          SettleRow(paymentId: payment.id, fee: _fees[payment.id]?.text),
      ],
      _accountId,
    );

    if (!mounted) return;

    if (failure == null) {
      Navigator.of(context).pop(true);

      return;
    }

    setState(() {
      _saving = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final many = widget.payments.length > 1;
    final received = _totalCents - _feeCents;
    final failure = _failure;

    return Padding(
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
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
                  many ? 'تسوية ${widget.payments.length} دفعات' : 'تسوية الدفعة',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ينتقل المال من حيث نزل إلى الحساب الذي وصل إليه — لا تتغيّر حالة الطلبية ولا '
                  'المدفوع، ويمكن التراجع لاحقاً.',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 16.h),

                for (final (index, payment) in widget.payments.indexed)
                  _PaymentRow(
                    payment: payment,
                    fee: _fees[payment.id],
                    error: failure?.fieldError('payments.$index.payment_id'),
                    feeError: failure?.fieldError('payments.$index.fee'),
                    onFeeChanged: () => setState(() {}),
                  ),

                SizedBox(height: 8.h),
                AppDropdown<SettlementAccount>(
                  value: widget.destinations.where((a) => a.id == _accountId).firstOrNull,
                  items: widget.destinations,
                  keyOf: (account) => account.id,
                  labelOf: (account) => account.name,
                  // No `subtitleOf`: with one, the closed field draws the placeholder row as an
                  // empty box, and «تلقائي — المصرف» — where the money goes — would not be read.
                  label: 'إلى',
                  prefixIcon: AppIcons.treasury,
                  // «تلقائي» only when the server has an answer for every one of them; a payment
                  // already in its place has none, and then an account must be named.
                  placeholder: _allHaveATarget ? _automatic : null,
                  hint: _allHaveATarget ? null : 'اختر الحساب',
                  validator: (value) =>
                      value == null && !_allHaveATarget ? 'اختر الحساب الذي وصل إليه المال' : null,
                  errorText: failure?.fieldError('account_id'),
                  onChanged: (account) => setState(() => _accountId = account?.id),
                ),

                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _feeCents > 0
                            ? 'يصل ${_money(received)} من ${_money(_totalCents)}'
                            : 'يصل ${_money(received)}',
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),

                // A refusal no row or field above can carry — a 403, a lost connection.
                if (failure != null &&
                    failure.hasErrorsBeyond({
                      'account_id',
                      for (var i = 0; i < widget.payments.length; i++) ...[
                        'payments.$i.payment_id',
                        'payments.$i.fee',
                      ],
                    }))
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      failure.message,
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ),

                SizedBox(height: 16.h),
                AppButton(
                  key: const ValueKey('settle-submit'),
                  label: 'تسوية',
                  icon: AppIcons.treasury,
                  isLoading: _saving,
                  onPressed: () => unawaited(_submit()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One payment in the sheet: which order, how much, where it is now — and, for a carrier's
/// money, what it kept.
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.fee,
    required this.error,
    required this.feeError,
    required this.onFeeChanged,
  });

  final OrderPayment payment;
  final TextEditingController? fee;
  final String? error;
  final String? feeError;
  final VoidCallback onFeeChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fee = this.fee;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (payment.order case final order?) '#${order.code}',
                    if (payment.treasuryAccount case final account?) 'في ${account.name}',
                  ].join(' · '),
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                payment.amount.grouped,
                textDirection: TextDirection.ltr,
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          if (error != null)
            Text(error!, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
          if (fee != null) ...[
            SizedBox(height: 6.h),
            AppTextField(
              key: ValueKey('settle-fee-${payment.id}'),
              controller: fee,
              label: 'احتفظ به الناقل',
              hint: 'اتركه فارغاً إن وصل كاملاً',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
              errorText: feeError,
              onChanged: (_) => onFeeChanged(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;

                return _cents(value) > _cents(payment.amount) ? 'أكبر من الدفعة' : null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// A typed or sent amount in whole dirhams — for the «يصل» line alone, never sent: the server
/// does the arithmetic that counts. Arabic digits and separator are read as the API reads them.
int _cents(String value) {
  final cleaned = normaliseAmount(value);

  if (cleaned.isEmpty) return 0;

  final parts = cleaned.split('.');
  final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first) ?? 0;
  final fraction = parts.length > 1 ? '${parts[1]}00'.substring(0, 2) : '00';

  return whole * 100 + (int.tryParse(fraction) ?? 0);
}

String _money(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final text = '${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';

  return '${negative ? '−' : ''}${text.grouped}';
}
