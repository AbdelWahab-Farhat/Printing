import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/uuid.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/purchase_order_payments_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_dialogs.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «المدفوع للمورد» على أمر الشراء — الإجمالي، وما دُفع عليه، وما خصمه المورد، وما بقي له،
/// وتحتها الدفعات، و«دفعة للمورد» و«خصم من المورد» — و«يُحسب عليه دين للمورد» لأمرٍ من قبل
/// الخزينة. TREASURY-DESIGN §٨، §٢٠.
///
/// **طلبُه وحده وصلاحيتُه وحدها.** شاشة الأمر تُرسم بدونه لمن لا يحمل `vendors.payments.view`،
/// والقراءة في [PurchaseOrderPaymentsCubit] — وفشلُها يُقال بزرّ «إعادة المحاولة» ولا يُسقط بقية
/// الأمر.
class PurchaseOrderPaymentsSection extends StatelessWidget {
  const PurchaseOrderPaymentsSection({
    required this.purchaseOrderId,
    required this.vendorId,
    super.key,
  });

  final int purchaseOrderId;
  final int vendorId;

  bool get _canView =>
      sl.isRegistered<Session>() && sl<Session>().can(AppPermission.viewVendorPayments);

  @override
  Widget build(BuildContext context) {
    if (!_canView || !sl.isRegistered<GetPurchaseOrderPayments>()) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (_) => PurchaseOrderPaymentsCubit(
        purchaseOrderId: purchaseOrderId,
        vendorId: vendorId,
        getPayments: sl(),
        payVendor: sl(),
        reversePayment: sl(),
        creditVendor: sl(),
        countAsDebt: sl(),
      )..load(),
      child: const _Section(),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PurchaseOrderPaymentsCubit, PurchaseOrderPaymentsState>(
      listener: (context, state) {
        if (state case PurchaseOrderPaymentsLoaded(:final refreshFailure?)) {
          context.showFailure(refreshFailure);
        }
      },
      builder: (context, state) => switch (state) {
        // القسم يُحمَّل وحده، والأمر لا ينتظره.
        PurchaseOrderPaymentsLoading() => const SizedBox.shrink(),
        PurchaseOrderPaymentsFailed(:final failure) => _Failed(failure: failure),
        PurchaseOrderPaymentsLoaded(:final payments) => _Loaded(payments: payments),
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.payments});

  final PurchaseOrderPayments payments;

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();
    final rows = payments.payments;

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
              // أمرٌ من قبل الخزينة لا متبقّي عليه، لكن يُدفع عليه حتى إجماليه ناقصاً ما دُفع منذ النظام.
              if (payments.predatesTreasury && payments.payableUpTo != null)
                ('يُدفع عليه حتى', payments.payableUpTo!),
            ],
            emphasis: payments.remaining == null ? null : ('المتبقي للمورد', payments.remaining!),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, payment) in rows.indexed) ...[
                  if (payment.paidAt case final at?
                      when startsNewDay(index == 0 ? null : rows[index - 1].paidAt, at))
                    DayHeader(at: at, first: index == 0),
                  _PaymentRow(
                    key: ValueKey(payment.id),
                    payment: payment,
                    movedMoney: _movedMoney(payment),
                    canReverse: session.can(AppPermission.reverseVendorPayments),
                  ),
                ],
                if (session.can(AppPermission.recordVendorPayments)) ...[
                  SizedBox(height: 8.h),
                  AppButton.tonal(
                    label: 'دفعة للمورد',
                    icon: AppIcons.payment,
                    onPressed: () => _pay(context, payments.payableUpTo ?? payments.remaining),
                  ),
                  // لا يُخصم مقدّماً (§٢٠): أمرٌ لم يبقَ عليه شيء لا يُعرض عليه خصم — والخادم يرفضه.
                  if (payments.remaining case final left? when left != '0.00') ...[
                    SizedBox(height: 8.h),
                    AppButton.tonal(
                      label: 'خصم من المورد',
                      icon: AppIcons.expense,
                      onPressed: () => _credit(context),
                    ),
                  ],
                  // أمرٌ قديم ما زال مستحقاً يدخل «علينا» باليد — النظام لا يعرف ما دُفع قبله (§٢٠).
                  if (payments.predatesTreasury && payments.total != null) ...[
                    SizedBox(height: 8.h),
                    AppButton.tonal(
                      label: 'يُحسب عليه دين للمورد',
                      icon: AppIcons.payable,
                      onPressed: () => _countAsDebt(context),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context, String? remaining) {
    final cubit = context.read<PurchaseOrderPaymentsCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PayVendorForm(cubit: cubit, suggested: remaining),
    );
  }

  Future<void> _credit(BuildContext context) {
    final cubit = context.read<PurchaseOrderPaymentsCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreditVendorForm(cubit: cubit),
    );
  }

  /// باتّجاهٍ واحد لا يُتراجع عنه، فيُسأل قبله.
  Future<void> _countAsDebt(BuildContext context) async {
    final cubit = context.read<PurchaseOrderPaymentsCubit>();

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

    if (!(confirmed ?? false) || !context.mounted) return;

    final failure = await cubit.countAsDebt();

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess('حُسب دين الأمر على المورد');
  }

  /// هل حرّك هذا الصفُّ مالاً؟ الدَّينُ الافتتاحي والخصمُ لا يحرّكانه، ولا عكسُهما.
  bool _movedMoney(VendorPayment payment) {
    final row = payment.isReversal
        ? payments.payments.where((p) => p.id == payment.reversesPaymentId).firstOrNull ?? payment
        : payment;

    return !row.isOpeningDebt && !row.isCredit;
  }
}

/// دفعةٌ واحدة — على شكل سطر الدفتر: نوعها وقصّتها على جهة القراءة، ومبلغُها بإشارته أكبرُ ما
/// في الصف. **الإشارة من جهة الشركة**: الدفعة مالٌ خرج (−)، وعكسُها مالٌ عاد (+)، والدَّين
/// الافتتاحي والخصمُ — وعكسُهما — بلا إشارة لأنها لم تحرّك مالاً.
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.movedMoney,
    required this.canReverse,
    super.key,
  });

  final VendorPayment payment;
  final bool movedMoney;
  final bool canReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final struck = payment.isReversed ? TextDecoration.lineThrough : null;
    final tone = payment.isReversed || !movedMoney
        ? scheme.onSurfaceVariant
        : payment.isReversal
        ? scheme.primary
        : scheme.error;
    final figure = !movedMoney
        ? treasuryMoney(payment.amount)
        : treasuryMoney(
            payment.isReversal ? payment.amount : '-${payment.amount}',
            signed: true,
          );

    final story = [?payment.methodLabel, ?payment.accountName, ?payment.recorderName].join(' · ');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.typeLabel,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: struck,
                  ),
                ),
                if (story.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(story, maxLines: 2, overflow: TextOverflow.ellipsis, style: quiet),
                ],
                if (payment.notes case final notes? when notes.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(notes, style: quiet?.copyWith(fontStyle: FontStyle.italic)),
                ],
                if (payment.paidAt case final at?) ...[
                  SizedBox(height: 4.h),
                  Text(at.timeLabel, style: quiet),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            figure,
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: tone,
              decoration: struck,
            ),
          ),
          if (canReverse && payment.isReversible)
            TreasuryOptionsButton(
              tooltip: 'خيارات الدفعة',
              onPressed: () => showTreasuryOptions(
                context,
                title: payment.typeLabel,
                subtitle: [
                  treasuryMoney(payment.amount),
                  if (payment.paidAt case final at?) at.dayLabel,
                ].join(' · '),
                options: [
                  TreasuryOption(
                    icon: AppIcons.reversePayment,
                    label: 'عكس الدفعة',
                    isDestructive: true,
                    onSelected: () => unawaited(_reverse(context)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _reverse(BuildContext context) async {
    final cubit = context.read<PurchaseOrderPaymentsCubit>();

    final reason = await askForReason(context, title: 'عكس الدفعة', confirmLabel: 'عكس الدفعة');

    if (reason == null || !context.mounted) return;

    final failure = await cubit.reverse(payment, reason: reason);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess('تم عكس الدفعة');
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'المدفوع للمورد',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6.h),
          Text(
            failure.message,
            style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.error),
          ),
          SizedBox(height: 8.h),
          AppButton.tonal(
            label: 'إعادة المحاولة',
            icon: AppIcons.refresh,
            onPressed: context.read<PurchaseOrderPaymentsCubit>().load,
          ),
        ],
      ),
    );
  }
}

/// «خصم من المورد» — نقصٌ في الشحنة أو تخفيض: يُنقص المستحق على الأمر ولا يحرّك مالاً، والخادم
/// يرفض أكثر مما بقي عليه ويقول ذلك تحت المبلغ.
class _CreditVendorForm extends StatefulWidget {
  const _CreditVendorForm({required this.cubit});

  final PurchaseOrderPaymentsCubit cubit;

  @override
  State<_CreditVendorForm> createState() => _CreditVendorFormState();
}

class _CreditVendorFormState extends State<_CreditVendorForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  /// مفتاح هذا النموذج: يولَّد مرةً ويُعاد مع كل محاولة، فلا يُسجَّل الخصم مرتين.
  final _clientToken = uuidV4();

  bool _saving = false;
  Failure? _refusal;

  static const _rendered = {'amount', 'notes'};

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _refusal = null;
    });

    final notes = _notes.text.trim();

    final failure = await widget.cubit.credit(
      amount: Validators.toWesternDigits(_amount.text.trim()),
      notes: notes.isEmpty ? null : notes,
      clientToken: _clientToken,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
      _refusal = failure;
    });

    if (failure != null) {
      if (failure.hasErrorsBeyond(_rendered)) context.showFailure(failure);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess('تم تسجيل الخصم');
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
              SizedBox(height: 20.h),
              AppTextField(
                controller: _amount,
                label: 'المبلغ',
                prefixIcon: AppIcons.payment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                errorText: _refusal?.fieldError('amount'),
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
                errorText: _refusal?.fieldError('notes'),
              ),
              SizedBox(height: 24.h),
              AppButton(label: 'تسجيل الخصم', isLoading: _saving, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

/// «دفعة للمورد» — كم، وكيف، ومن أيّ درج. الدرج يجب أن يكفي: الخادم يرفض دفعةً لا يغطيها
/// الحساب، ويقول ذلك تحت المبلغ.
class _PayVendorForm extends StatefulWidget {
  const _PayVendorForm({required this.cubit, this.suggested});

  final PurchaseOrderPaymentsCubit cubit;

  /// المتبقي للمورد — يُفتح عليه المبلغ ما دام موجباً.
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

  /// مفتاح هذا النموذج: يولَّد مرةً ويُعاد مع كل محاولة، فلا تُسجَّل الدفعة مرتين.
  final _clientToken = uuidV4();

  PaymentMethod _method = PaymentMethod.bankTransfer;
  int? _accountId;
  bool _saving = false;
  Failure? _refusal;

  static const _rendered = {'amount', 'method', 'treasury_account_id', 'reference', 'notes'};

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _refusal = null;
    });

    final reference = _reference.text.trim();
    final notes = _notes.text.trim();

    final failure = await widget.cubit.pay(
      amount: Validators.toWesternDigits(_amount.text.trim()),
      method: _method.wire,
      accountId: _accountId,
      reference: reference.isEmpty ? null : reference,
      notes: notes.isEmpty ? null : notes,
      clientToken: _clientToken,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
      _refusal = failure;
    });

    if (failure != null) {
      if (failure.hasErrorsBeyond(_rendered)) context.showFailure(failure);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess('تم تسجيل الدفعة');
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
                errorText: _refusal?.fieldError('amount'),
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
                errorText: _refusal?.fieldError('method'),
                onChanged: (method) {
                  if (method == null) return;

                  setState(() {
                    _method = method;
                    // حسابٌ اختير للكاش لا يناسب الحوالة.
                    _accountId = null;
                  });
                },
              ),
              SizedBox(height: 16.h),
              TreasuryAccountPicker(
                method: _method.wire,
                incoming: false,
                value: _accountId,
                errorText: _refusal?.fieldError('treasury_account_id'),
                onChanged: (id) => setState(() => _accountId = id),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: _reference,
                label: 'رقم المرجع (اختياري)',
                prefixIcon: AppIcons.tag,
                errorText: _refusal?.fieldError('reference'),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: _notes,
                label: 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                maxLines: 2,
                errorText: _refusal?.fieldError('notes'),
              ),
              SizedBox(height: 24.h),
              AppButton(label: 'تسجيل الدفعة', isLoading: _saving, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
