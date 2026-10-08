import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/widgets/settlement_account_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// رأسُ قائمتَي «مراجعة وتسوية الدفعات» — طلب صاحب العمل ٢٠٢٦-١٠-٠٨.
///
/// **البحث، وبجانبه زرُّ الفلتر المتقدّم، وتحتهما أزرار الفترة** (الكل · اليوم · هذا الأسبوع ·
/// هذا الشهر) على «الكل». يُرسم في `PagedListView.header`، فيمرّ مع الصفوف ولا يمسك أعلى الشاشة.
/// «من» / «إلى» والحساب أو النوع في الفلتر المتقدّم ([showPaymentAdvancedFilter]).
///
/// **خلفيةٌ مُصمتة**: حين يعود الرأس مع التمرير إلى الأعلى يُرسم فوق الصفوف، ولا يجوز أن تظهر من خلاله.
class PaymentQueueFilters extends StatelessWidget {
  const PaymentQueueFilters({
    required this.period,
    required this.onPeriod,
    required this.onSearch,
    required this.isAdvancedActive,
    required this.onAdvanced,
    this.top,
    super.key,
  });

  final SettlementPeriod period;
  final ValueChanged<SettlementPeriod> onPeriod;
  final ValueChanged<String> onSearch;

  /// Whether the advanced filter narrows the list — fills its button.
  final bool isAdvancedActive;
  final VoidCallback onAdvanced;

  /// Above the search box — the settlement tab's «بانتظار التسوية / مسوّاة».
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (top case final top?) ...[top, SizedBox(height: 12.h)],
            Row(
              children: [
                Expanded(
                  child: SearchField(
                    key: const ValueKey('payment-search'),
                    hint: 'ابحث برقم الطلبية أو اسم الزبون',
                    onChanged: onSearch,
                  ),
                ),
                SizedBox(width: 8.w),
                _AdvancedButton(isActive: isAdvancedActive, onTap: onAdvanced),
              ],
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final chip in SettlementPeriod.chips)
                  FilterOptionChip(
                    key: ValueKey('period-${chip.name}'),
                    label: chip.label,
                    isSelected: chip == period,
                    onTap: () => onPeriod(chip),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The round button beside the search box — the purchase-order list's, filled while the advanced
/// filter narrows anything, so whether it does is answered before the sheet is opened.
class _AdvancedButton extends StatelessWidget {
  const _AdvancedButton({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      key: const ValueKey('advanced-filter'),
      color: isActive ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(13.w),
          child: Icon(
            AppIcons.filter,
            size: 22.sp,
            color: isActive ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// What the advanced filter answers with on «تطبيق». Empty fields narrow nothing; a dismissed
/// sheet answers null instead, so swiping it away is never mistaken for clearing it.
@immutable
class PaymentAdvancedFilter {
  const PaymentAdvancedFilter({this.from, this.to, this.accountId, this.type});

  final DateTime? from;
  final DateTime? to;

  /// Where the money waits — the settlement list's question.
  final int? accountId;

  /// Payments or refunds — the review list's question.
  final OrderPaymentType? type;
}

/// «تصفية متقدمة»: «من» and «إلى» as two fields of their own, each opening a calendar, and under
/// them the list's own question — [accounts] for the settlement list (null leaves it out), or the
/// type for the review list ([offersType]).
Future<PaymentAdvancedFilter?> showPaymentAdvancedFilter({
  required BuildContext context,
  required PaymentAdvancedFilter current,
  List<SettlementAccount>? accounts,
  bool offersType = false,
}) {
  return showModalBottomSheet<PaymentAdvancedFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AdvancedSheet(current: current, accounts: accounts, offersType: offersType),
  );
}

/// Stateful for the reason the purchase-order sheet is: the choices apply on «تطبيق», so «مسح
/// الفلاتر» has something to clear and a mis-tap is corrected without reopening the sheet.
class _AdvancedSheet extends StatefulWidget {
  const _AdvancedSheet({required this.current, required this.accounts, required this.offersType});

  final PaymentAdvancedFilter current;
  final List<SettlementAccount>? accounts;
  final bool offersType;

  @override
  State<_AdvancedSheet> createState() => _AdvancedSheetState();
}

class _AdvancedSheetState extends State<_AdvancedSheet> {
  late DateTime? _from = widget.current.from;
  late DateTime? _to = widget.current.to;
  late int? _accountId = widget.current.accountId;
  late OrderPaymentType? _type = widget.current.type;

  bool get _hasAny => _from != null || _to != null || _accountId != null || _type != null;

  /// «من» may not pass «إلى», nor «إلى» come before «من» — each calendar is bounded by the other.
  Future<void> _pick({required bool isFrom}) async {
    final today = DateTime.now();
    final last = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? (isFrom ? _to : null) ?? last,
      firstDate: isFrom ? DateTime(2024) : (_from ?? DateTime(2024)),
      lastDate: isFrom ? (_to ?? last) : last,
    );

    if (picked == null || !mounted) return;

    setState(() => isFrom ? _from = picked : _to = picked);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.accounts;
    final account = accounts?.where((a) => a.id == _accountId).firstOrNull;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 8.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'تصفية متقدمة',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (_hasAny)
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() {
                        _from = null;
                        _to = null;
                        _accountId = null;
                        _type = null;
                      }),
                      child: const Text('مسح الفلاتر'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FilterSectionTitle(title: 'الفترة'),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'من',
                          value: _from,
                          onTap: () => _pick(isFrom: true),
                          onClear: () => setState(() => _from = null),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _DateField(
                          label: 'إلى',
                          value: _to,
                          onTap: () => _pick(isFrom: false),
                          onClear: () => setState(() => _to = null),
                        ),
                      ),
                    ],
                  ),
                  if (accounts != null) ...[
                    SizedBox(height: 18.h),
                    const FilterSectionTitle(title: 'الحساب'),
                    SizedBox(height: 10.h),
                    AppTextField(
                      // Keyed on the choice: the field shows a value it was handed, and a new
                      // choice is a new value rather than an edit to the old one.
                      key: ValueKey('advanced-account-${_accountId ?? 'all'}'),
                      initialValue: account?.name ?? 'كل الحسابات',
                      prefixIcon: AppIcons.treasury,
                      readOnly: true,
                      enabled: accounts.isNotEmpty,
                      suffix: account == null
                          ? null
                          : IconButton(
                              tooltip: 'كل الحسابات',
                              onPressed: () => setState(() => _accountId = null),
                              icon: Icon(AppIcons.close),
                            ),
                      onTap: () async {
                        final choice = await showSettlementAccountPicker(
                          context: context,
                          accounts: accounts,
                          selectedId: _accountId,
                        );

                        if (choice != null && mounted) setState(() => _accountId = choice.accountId);
                      },
                    ),
                  ],
                  if (widget.offersType) ...[
                    SizedBox(height: 18.h),
                    const FilterSectionTitle(title: 'النوع'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final (type, label) in const [
                          (null, 'الكل'),
                          (OrderPaymentType.payment, 'دفعات'),
                          (OrderPaymentType.refund, 'ردود'),
                        ])
                          FilterOptionChip(
                            label: label,
                            isSelected: _type == type,
                            onTap: () => setState(() => _type = type),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
              child: AppButton(
                key: const ValueKey('apply-advanced'),
                label: 'تطبيق',
                onPressed: () => Navigator.of(context).pop(
                  PaymentAdvancedFilter(from: _from, to: _to, accountId: _accountId, type: _type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «من» or «إلى» — a field that opens a calendar, with a cross to leave it open again.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final day = value;

    return AppTextField(
      // Keyed on the day for the account field's reason: a new day is a new value.
      key: ValueKey('advanced-$label-${day?.toIso8601String() ?? 'none'}'),
      initialValue: day?.dayLabel,
      label: label,
      prefixIcon: AppIcons.today,
      readOnly: true,
      suffix: day == null
          ? null
          : IconButton(
              tooltip: 'مسح',
              onPressed: onClear,
              icon: Icon(AppIcons.close),
            ),
      onTap: onTap,
    );
  }
}
