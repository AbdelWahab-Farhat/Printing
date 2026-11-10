import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/uuid.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/treasury/models/exchange_figures.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What records the exchange — the dashboard's cubit or the account page's. Null on success.
///
/// [amount] left [fromAccountId] in its currency; [counterAmount] arrived in the other; [rate]
/// is dinars per dollar. Two of the three are sent, the two the person typed.
typedef RecordExchangeCallback =
    Future<Failure?> Function({
      required int fromAccountId,
      required int toAccountId,
      String? amount,
      String? counterAmount,
      String? rate,
      String? notes,
      String? clientToken,
    });

/// «صرف عملة» — dinars into dollars or back. USD-ACCOUNTS §٣.
///
/// **Three figures, any two typed** — dinars, dollars, the rate. The third is worked out as the
/// person types and shown greyed as «محسوب»; only the two typed are sent, and the server works
/// out the third the same way.
///
/// Opened from an account, that account starts on its natural side — a dinar box pays for the
/// dollars, a dollar account receives them — and «⇅» turns the direction round.
///
/// [onUpdateSystemRate] is passed only to somebody who may change «إعدادات المالية»: it offers
/// to make the rate just used «سعر النظام».
Future<void> showCurrencyExchangeSheet({
  required BuildContext context,
  required List<TreasuryAccount> accounts,
  required RecordExchangeCallback onSubmit,
  TreasuryAccount? account,
  Future<Failure?> Function(String rate)? onUpdateSystemRate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ExchangeForm(
      accounts: accounts,
      account: account,
      onSubmit: onSubmit,
      onUpdateSystemRate: onUpdateSystemRate,
    ),
  );
}

/// What makes the rate just used «سعر النظام» — for somebody who may change «إعدادات المالية»,
/// and null for everybody else, so the sheet does not offer it.
Future<Failure?> Function(String rate)? systemRateUpdater(Session session) {
  if (!session.can(AppPermission.manageTreasury)) return null;

  return (rate) async {
    final result = await sl<SaveTreasurySettings>()(usdRate: rate);

    return result.fold((failure) => failure, (_) => null);
  };
}

/// The accounts that may take part: active cash boxes, banks and Libyana, in either currency.
/// Custody, payables and the system's own accounts never exchange — the server says the same.
List<TreasuryAccount> exchangeableAccounts(List<TreasuryAccount> accounts) => [
  for (final account in accounts)
    if (account.isActive && account.isSpendable && !account.isPayable && !account.isSystem) account,
];

class _ExchangeForm extends StatefulWidget {
  const _ExchangeForm({
    required this.accounts,
    required this.onSubmit,
    this.account,
    this.onUpdateSystemRate,
  });

  final List<TreasuryAccount> accounts;
  final TreasuryAccount? account;
  final RecordExchangeCallback onSubmit;
  final Future<Failure?> Function(String rate)? onUpdateSystemRate;

  @override
  State<_ExchangeForm> createState() => _ExchangeFormState();
}

class _ExchangeFormState extends State<_ExchangeForm> {
  final _formKey = GlobalKey<FormState>();
  final _lyd = TextEditingController();
  final _usd = TextEditingController();
  final _rate = TextEditingController();
  final _notes = TextEditingController();

  /// Generated once and sent with every attempt, so a retry after a lost reply writes nothing
  /// twice (`client_token`).
  final _clientToken = uuidV4();

  TreasuryAccount? _from;
  TreasuryAccount? _to;

  /// The figures the person typed, the latest first — never more than two. The third is the
  /// one worked out.
  final List<String> _typed = [];

  bool _updateSystemRate = false;
  bool _saving = false;
  Failure? _refusal;

  late final List<TreasuryAccount> _choices = exchangeableAccounts(widget.accounts);

  TextEditingController _controllerOf(String figure) => switch (figure) {
    'lyd' => _lyd,
    'usd' => _usd,
    _ => _rate,
  };

  /// The figure not typed — worked out once two are.
  String? get _worked => _typed.length < 2
      ? null
      : const ['lyd', 'usd', 'rate'].firstWhere((figure) => !_typed.contains(figure));

  /// Buying dollars: dinars leave. The server's `amount` is whatever left.
  bool get _buyingDollars => !(_from?.isDollar ?? false);

  /// The fields shown under each box: what the server calls them depends on the direction.
  Set<String> get _rendered => {
    'amount',
    'counter_amount',
    'rate',
    'from_account_id',
    'to_account_id',
    'notes',
  };

  @override
  void initState() {
    super.initState();

    final start = _choices.where((account) => account.id == widget.account?.id).firstOrNull;

    if (start == null) return;

    // When one account alone is in the other currency — the usual single dollar box — it is
    // the other side, and nothing is left to pick.
    final others = [
      for (final account in _choices)
        if (account.currency != start.currency) account,
    ];
    final other = others.length == 1 ? others.single : null;

    if (start.isDollar) {
      _to = start;
      _from = other;
    } else {
      _from = start;
      _to = other;
    }
  }

  @override
  void dispose() {
    _lyd.dispose();
    _usd.dispose();
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _figure(TextEditingController controller) =>
      Validators.toWesternDigits(controller.text.trim());

  /// A person typed in [figure]: it becomes one of the two latest, and the third is worked out —
  /// or emptied, while there is not enough to work it out from.
  void _typedIn(String figure, String text) {
    setState(() {
      _typed.remove(figure);

      if (text.trim().isNotEmpty) _typed.insert(0, figure);
      if (_typed.length > 2) _typed.removeLast();

      final worked = _worked;

      for (final other in const ['lyd', 'usd', 'rate']) {
        if (!_typed.contains(other) && other != figure) {
          _controllerOf(other).text = other == worked
              ? completeExchange(
                      typed: _typed.toSet(),
                      lyd: _figure(_lyd),
                      usd: _figure(_usd),
                      rate: _figure(_rate),
                    ) ??
                    ''
              : '';
        }
      }
    });
  }

  void _swap() {
    setState(() {
      final from = _from;
      _from = _to;
      _to = from;
    });
  }

  String? _validateFigure(String figure, String? value) {
    if (!_typed.contains(figure) && figure == _worked) return null;
    if (_typed.length < 2 && (value ?? '').trim().isEmpty) {
      return figure == 'rate' ? null : 'اكتب اثنين من ثلاثة';
    }
    if ((value ?? '').trim().isEmpty) return null;

    final number = double.tryParse(Validators.toWesternDigits(value!.trim()));

    if (number == null) return 'يجب أن يكون رقماً';
    if (number <= 0) return 'يجب أن يكون أكبر من صفر';

    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_typed.length < 2) {
      context.showError('اكتب اثنين من ثلاثة: المبلغ بالدينار، المبلغ بالدولار، السعر');

      return;
    }

    final from = _from!;
    final to = _to!;
    String? sent(String figure) => _typed.contains(figure) ? _figure(_controllerOf(figure)) : null;
    final notes = _notes.text.trim();

    setState(() {
      _saving = true;
      _refusal = null;
    });

    final failure = await widget.onSubmit(
      fromAccountId: from.id,
      toAccountId: to.id,
      amount: sent(_buyingDollars ? 'lyd' : 'usd'),
      counterAmount: sent(_buyingDollars ? 'usd' : 'lyd'),
      rate: sent('rate'),
      notes: notes.isEmpty ? null : notes,
      clientToken: _clientToken,
    );

    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _saving = false;
        _refusal = failure;
      });

      if (failure.hasErrorsBeyond(_rendered)) context.showFailure(failure);

      return;
    }

    // Once the exchange stands, and before the sheet closes: a refused rate update is said, and
    // the exchange stays written.
    final rate = _figure(_rate);
    final updateRate = widget.onUpdateSystemRate;

    if (_updateSystemRate && updateRate != null && rate.isNotEmpty) {
      final refused = await updateRate(rate);

      if (!mounted) return;
      if (refused != null) context.showFailure(refused);
    }

    Navigator.of(context).pop();
    context.showSuccess('تم تسجيل «صرف عملة»');
  }

  String? _errorFor(String figure) => switch (figure) {
    'rate' => _refusal?.fieldError('rate'),
    'lyd' => _refusal?.fieldError(_buyingDollars ? 'amount' : 'counter_amount'),
    _ => _refusal?.fieldError(_buyingDollars ? 'counter_amount' : 'amount'),
  };

  Widget _figureField(String figure, String label, IconData icon) {
    final worked = figure == _worked && !_typed.contains(figure);

    return AppTextField(
      key: ValueKey('exchange-$figure'),
      controller: _controllerOf(figure),
      label: label,
      helperText: worked ? 'محسوب من الحقلين الآخرين' : null,
      prefixIcon: icon,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
      textDirection: TextDirection.ltr,
      errorText: _errorFor(figure),
      onChanged: (text) => _typedIn(figure, text),
      validator: (value) => _validateFigure(figure, value),
    );
  }

  Widget _accountPicker({
    required String label,
    required TreasuryAccount? value,
    required List<TreasuryAccount> items,
    required String errorKey,
    required ValueChanged<TreasuryAccount?> onChanged,
  }) {
    return AppDropdown<TreasuryAccount>(
      key: ValueKey('exchange-$errorKey'),
      value: items.any((account) => account.id == value?.id) ? value : null,
      items: items,
      keyOf: (account) => account.id,
      labelOf: (account) => '${account.name} — ${treasuryBalanceLabel(account)}',
      iconOf: (account) => accountKindIcon(account.kind),
      label: label,
      errorText: _refusal?.fieldError(errorKey),
      onChanged: onChanged,
      validator: (account) => account == null ? '$label مطلوب' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    // The other side is in the other currency — that is what makes it an exchange.
    final targets = [
      for (final account in _choices)
        if (_from == null || account.currency != _from!.currency) account,
    ];
    final sources = [
      for (final account in _choices)
        if (_to == null || account.currency != _to!.currency) account,
    ];

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
                'صرف عملة',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 20.h),

              _accountPicker(
                label: 'من حساب',
                value: _from,
                items: sources,
                errorKey: 'from_account_id',
                onChanged: (account) => setState(() => _from = account),
              ),
              Center(
                child: IconButton(
                  key: const ValueKey('exchange-swap'),
                  tooltip: 'عكس الاتجاه',
                  icon: Icon(AppIcons.exchange),
                  onPressed: _swap,
                ),
              ),
              _accountPicker(
                label: 'إلى حساب',
                value: _to,
                items: targets,
                errorKey: 'to_account_id',
                onChanged: (account) => setState(() => _to = account),
              ),
              SizedBox(height: 20.h),

              Text(
                'اكتب اثنين من الثلاثة، ويُحسب الثالث',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: 12.h),
              _figureField('lyd', 'المبلغ بالدينار', AppIcons.payment),
              SizedBox(height: 16.h),
              _figureField('usd', 'المبلغ بالدولار', AppIcons.payment),
              SizedBox(height: 16.h),
              _figureField('rate', 'السعر — دينار لكل دولار', AppIcons.exchange),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _notes,
                label: 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                errorText: _refusal?.fieldError('notes'),
              ),

              if (widget.onUpdateSystemRate != null)
                CheckboxListTile(
                  key: const ValueKey('exchange-update-rate'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _updateSystemRate,
                  title: const Text('اجعل هذا السعر «سعر النظام»'),
                  subtitle: const Text('به تُحسب قيمة الدولار في مجاميع الحسابات'),
                  onChanged: (value) => setState(() => _updateSystemRate = value ?? false),
                ),
              SizedBox(height: 24.h),

              AppButton(label: 'تسجيل صرف العملة', isLoading: _saving, onPressed: _submit),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
