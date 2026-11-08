import 'dart:async';

import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/widgets/settlement_account_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// رأسُ قائمتَي «مراجعة وتسوية الدفعات» — طلب صاحب العمل ٢٠٢٦-١٠-٠٨.
///
/// **البحث، وبجانبه زرُّ الفلتر المتقدّم، وتحتهما أزرار الفترة** (الكل · اليوم · هذا الأسبوع ·
/// هذا الشهر) على «الكل». يُرسم في `PagedListView.header`، فيمرّ مع الصفوف ولا يمسك أعلى الشاشة.
/// وبقية الأسئلة في الفلتر المتقدّم ([showPaymentAdvancedFilter]).
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
  const PaymentAdvancedFilter({
    this.from,
    this.to,
    this.accountId,
    this.type,
    this.detail = const PaymentDetailFilter(),
  });

  final DateTime? from;
  final DateTime? to;

  /// حيث نزل المال — زرٌّ من «نوع الدفعة» أو حسابٌ من «حساب آخر».
  final int? accountId;

  /// Payments or refunds — the review list's question.
  final OrderPaymentType? type;

  /// بقية ما في الورقة، ومنها طريقة الدفع حين يكون الزرّ طريقةً لا حساباً.
  final PaymentDetailFilter detail;
}

/// «تصفية متقدمة» — طلب صاحب العمل ٢٠٢٦-١١-٠٧: الفترة، ودفعة أو ردّ في المراجعة، و«نوع الدفعة»،
/// ومَن سجّل، والمبلغ. و[offersSettled] يزيد ما لا يُسأل إلا عن «مسوّاة»: إلى أين ذهبت ومَن سوّاها.
///
/// [options] فارغةٌ حين تعذّر طلبها، فتُترك أقسامها ويبقى ما لا يحتاج الخادم.
Future<PaymentAdvancedFilter?> showPaymentAdvancedFilter({
  required BuildContext context,
  required PaymentAdvancedFilter current,
  required PaymentFilterOptions options,
  bool offersType = false,
  bool offersSettled = false,
}) {
  return showModalBottomSheet<PaymentAdvancedFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AdvancedSheet(
      current: current,
      options: options,
      offersType: offersType,
      offersSettled: offersSettled,
    ),
  );
}

/// Stateful for the reason the purchase-order sheet is: the choices apply on «تطبيق», so «مسح
/// الفلاتر» has something to clear and a mis-tap is corrected without reopening the sheet.
///
/// **الرأس و«تطبيق» ثابتان وما بينهما يتمرّر**: الورقة طالت، ولا يجوز أن يغيب زرّها تحت الأسئلة.
class _AdvancedSheet extends StatefulWidget {
  const _AdvancedSheet({
    required this.current,
    required this.options,
    required this.offersType,
    required this.offersSettled,
  });

  final PaymentAdvancedFilter current;
  final PaymentFilterOptions options;
  final bool offersType;
  final bool offersSettled;

  @override
  State<_AdvancedSheet> createState() => _AdvancedSheetState();
}

class _AdvancedSheetState extends State<_AdvancedSheet> {
  late DateTime? _from = widget.current.from;
  late DateTime? _to = widget.current.to;
  late int? _accountId = widget.current.accountId;
  late OrderPaymentType? _type = widget.current.type;
  late PaymentMethod? _method = widget.current.detail.method;
  late int? _recordedBy = widget.current.detail.recordedBy;
  late int? _toAccountId = widget.current.detail.toAccountId;
  late int? _settledBy = widget.current.detail.settledBy;

  late final _minAmount = TextEditingController(text: widget.current.detail.minAmount);
  late final _maxAmount = TextEditingController(text: widget.current.detail.maxAmount);

  List<SettlementAccount> get _accounts => widget.options.accounts;

  bool get _hasAny =>
      _from != null ||
      _to != null ||
      _accountId != null ||
      _type != null ||
      _method != null ||
      _recordedBy != null ||
      _toAccountId != null ||
      _settledBy != null ||
      _minAmount.text.isNotEmpty ||
      _maxAmount.text.isNotEmpty;

  @override
  void dispose() {
    _minAmount.dispose();
    _maxAmount.dispose();
    super.dispose();
  }

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

  void _clear() {
    _minAmount.clear();
    _maxAmount.clear();

    setState(() {
      _from = null;
      _to = null;
      _accountId = null;
      _type = null;
      _method = null;
      _recordedBy = null;
      _toAccountId = null;
      _settledBy = null;
    });
  }

  /// زرٌّ يحلّ محلّ ما قبله، طريقةً كان أو حساباً.
  void _pickKind({PaymentMethod? method, int? accountId}) => setState(() {
    _method = method;
    _accountId = accountId;
  });

  bool _isKind(PaymentKind kind) => _method == kind.method && _accountId == kind.accountId;

  /// «حساب آخر»: كل حسابٍ ليس له زرّ.
  Future<void> _pickOtherAccount() async {
    final choice = await showSettlementAccountPicker(
      context: context,
      accounts: _accounts,
      selectedId: _accountId,
    );

    if (choice != null && mounted) _pickKind(accountId: choice.accountId);
  }

  Future<void> _pickSettledTo() async {
    final choice = await showSettlementAccountPicker(
      context: context,
      accounts: _accounts,
      selectedId: _toAccountId,
    );

    if (choice != null && mounted) setState(() => _toAccountId = choice.accountId);
  }

  /// ما كُتب بأرقامٍ يقرؤها الخادم، أو null. وما ليس رقماً لا يُضيِّق شيئاً.
  static String? _amountOf(TextEditingController field) {
    final text = Validators.toWesternDigits(field.text.trim());

    return double.tryParse(text) == null ? null : text;
  }

  void _apply() {
    final low = _amountOf(_minAmount);
    final high = _amountOf(_maxAmount);
    // حدٌّ أدنى فوق الأعلى خطأُ ترتيبٍ لا سؤالٌ بلا جواب: يُقرأ مقلوباً، ولا يرفضه الخادم.
    final isSwapped = low != null && high != null && double.parse(high) < double.parse(low);

    Navigator.of(context).pop(
      PaymentAdvancedFilter(
        from: _from,
        to: _to,
        accountId: _accountId,
        type: _type,
        detail: PaymentDetailFilter(
          method: _method,
          recordedBy: _recordedBy,
          minAmount: isSwapped ? high : low,
          maxAmount: isSwapped ? low : high,
          toAccountId: _toAccountId,
          settledBy: _settledBy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // الحقول المكتوبة ترفع الورقة فوق لوحة المفاتيح، و«تطبيق» معها.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 18.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _sections(),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
              child: AppButton(
                key: const ValueKey('apply-advanced'),
                label: 'تطبيق',
                onPressed: _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 8.w, 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'تصفية متقدمة',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          // المكان محجوزٌ بالارتفاع نفسه، فلا يقفز الرأس حين يظهر الزرّ.
          SizedBox(
            height: 40.h,
            child: _hasAny
                ? TextButton(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: _clear,
                    child: const Text('مسح الفلاتر'),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _sections() {
    final options = widget.options;

    return [
      _Section(
        title: 'الفترة',
        child: _Pair(
          first: _DateField(
            label: 'من',
            value: _from,
            onTap: () => _pick(isFrom: true),
            onClear: () => setState(() => _from = null),
          ),
          second: _DateField(
            label: 'إلى',
            value: _to,
            onTap: () => _pick(isFrom: false),
            onClear: () => setState(() => _to = null),
          ),
        ),
      ),
      if (widget.offersType)
        _Section(
          title: 'دفعة أو ردّ',
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final (type, label) in const [
                (null, 'الكل'),
                (OrderPaymentType.payment, 'دفعات'),
                (OrderPaymentType.refund, 'ردود'),
              ])
                FilterOptionChip(
                  key: ValueKey('entry-type-${type?.name ?? 'all'}'),
                  label: label,
                  isSelected: _type == type,
                  onTap: () => setState(() => _type = type),
                ),
            ],
          ),
        ),
      if (options.kinds.isNotEmpty || _accounts.isNotEmpty) _Section(title: 'نوع الدفعة', child: _kinds()),
      if (options.recorders.isNotEmpty)
        _Section(
          title: 'مَن سجّل',
          child: _PersonField(
            key: const ValueKey('recorded-by'),
            people: options.recorders,
            selectedId: _recordedBy,
            onChanged: (id) => setState(() => _recordedBy = id),
          ),
        ),
      _Section(
        title: 'المبلغ',
        child: _Pair(
          first: _AmountField(
            key: const ValueKey('amount-min'),
            label: 'من',
            controller: _minAmount,
            onChanged: () => setState(() {}),
          ),
          second: _AmountField(
            key: const ValueKey('amount-max'),
            label: 'إلى',
            controller: _maxAmount,
            onChanged: () => setState(() {}),
          ),
        ),
      ),
      if (widget.offersSettled) ...[
        if (_accounts.isNotEmpty) _Section(title: 'سُوّيت إلى', child: _settledToField()),
        if (options.settlers.isNotEmpty)
          _Section(
            title: 'مَن سوّى',
            child: _PersonField(
              key: const ValueKey('settled-by'),
              people: options.settlers,
              selectedId: _settledBy,
              onChanged: (id) => setState(() => _settledBy = id),
            ),
          ),
      ],
    ];
  }

  /// الأزرار، و«حساب آخر» بعدها يلبس اسم الحساب حين يُختار ما ليس له زرّ.
  Widget _kinds() {
    final kinds = widget.options.kinds;
    final isButton = kinds.any((kind) => kind.accountId != null && kind.accountId == _accountId);
    final other = isButton ? null : _accounts.where((a) => a.id == _accountId).firstOrNull;

    return Wrap(
      key: const ValueKey('payment-kinds'),
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        FilterOptionChip(
          key: const ValueKey('kind-all'),
          label: 'الكل',
          isSelected: _method == null && _accountId == null,
          onTap: _pickKind,
        ),
        for (final kind in kinds)
          FilterOptionChip(
            label: kind.label,
            isSelected: _isKind(kind),
            onTap: () => _pickKind(method: kind.method, accountId: kind.accountId),
          ),
        if (_accounts.isNotEmpty)
          FilterOptionChip(
            key: const ValueKey('kind-other'),
            label: other?.name ?? 'حساب آخر',
            isSelected: other != null,
            onTap: () => unawaited(_pickOtherAccount()),
          ),
      ],
    );
  }

  Widget _settledToField() {
    final account = _accounts.where((a) => a.id == _toAccountId).firstOrNull;

    return AppTextField(
      // Keyed on the choice: the field shows a value it was handed, and a new choice is a new
      // value rather than an edit to the old one.
      key: ValueKey('settled-to-${_toAccountId ?? 'none'}'),
      initialValue: account?.name ?? 'كل الحسابات',
      prefixIcon: AppIcons.treasury,
      readOnly: true,
      suffix: account == null
          ? null
          : IconButton(
              tooltip: 'كل الحسابات',
              onPressed: () => setState(() => _toAccountId = null),
              icon: Icon(AppIcons.close),
            ),
      onTap: () => unawaited(_pickSettledTo()),
    );
  }
}

/// سؤالٌ في الورقة: عنوانه وما تحته، بالمسافة نفسها في كل قسم.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterSectionTitle(title: title),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }
}

/// حقلان متجاوران بعرضٍ واحد: «من» و«إلى».
class _Pair extends StatelessWidget {
  const _Pair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: first),
        SizedBox(width: 10.w),
        Expanded(child: second),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.label,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
      onChanged: (_) => onChanged(),
    );
  }
}

/// موظفٌ من القائمة، و«الكل» أوّلها.
class _PersonField extends StatelessWidget {
  const _PersonField({
    required this.people,
    required this.selectedId,
    required this.onChanged,
    super.key,
  });

  final List<PaymentPerson> people;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<PaymentPerson>(
      items: people,
      value: people.where((person) => person.id == selectedId).firstOrNull,
      labelOf: (person) => person.name,
      keyOf: (person) => person.id,
      placeholder: 'الكل',
      prefixIcon: AppIcons.person,
      onChanged: (person) => onChanged(person?.id),
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
      // نصف عرض الورقة لا يتّسع للتاريخ بين أيقونتين: كان اليوم يُقصّ، فتُخلي الأيقونةُ مكانها له.
      prefixIcon: day == null ? AppIcons.today : null,
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
