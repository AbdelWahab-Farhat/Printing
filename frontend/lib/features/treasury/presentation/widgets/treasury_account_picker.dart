import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «الحساب» on a payment form — which account the money lands in, or leaves from.
///
/// **«تلقائي» is the first chip and the usual answer**: left there, the server puts the money in
/// the person's own account or the method's default, and names which one beside the chip. The
/// list is asked of the server for the method chosen, so a bank transfer is never offered the
/// cash box, and money leaving is never offered Nawris's custody (TREASURY-DESIGN §٥).
///
/// **It asks and then steps aside.** A form works without it — every payment endpoint picks an
/// account on its own — so a list that fails to load, or a build where the treasury is not
/// registered, simply draws nothing.
class TreasuryAccountPicker extends StatefulWidget {
  const TreasuryAccountPicker({
    required this.method,
    required this.value,
    required this.onChanged,
    this.incoming = true,
    this.label = 'الحساب',
    this.orderId,
    super.key,
  });

  /// The order the money is for — while it waits at a pickup branch, «تلقائي» is that branch's
  /// cash box (TREASURY-DESIGN §١٩).
  final int? orderId;

  /// The payment method's wire value — `cash`, `bank_transfer`, `bank_card`, `libyana`.
  ///
  /// **Null for a form that asks which drawer paid rather than how** — a fund expense. It then
  /// offers every active account money can be paid out of, and «تلقائي» is the cash box.
  final String? method;
  final bool incoming;
  final String label;

  /// The account picked, or null for «تلقائي».
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  State<TreasuryAccountPicker> createState() => _TreasuryAccountPickerState();
}

class _TreasuryAccountPickerState extends State<TreasuryAccountPicker> {
  AccountOptions? _options;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TreasuryAccountPicker old) {
    super.didUpdateWidget(old);

    if (old.method != widget.method ||
        old.incoming != widget.incoming ||
        old.orderId != widget.orderId) {
      setState(() => _options = null);
      _load();
    }
  }

  Future<void> _load() async {
    final method = widget.method;

    if (method == null) return _loadSpendable();

    if (!sl.isRegistered<GetAccountOptions>()) return;

    final result = await sl<GetAccountOptions>()(
      method: method,
      incoming: widget.incoming,
      orderId: widget.orderId,
    );

    // The method changed while this was in flight — the answer belongs to another question.
    if (!mounted || method != widget.method) return;

    result.fold((_) {}, (options) => setState(() => _options = options));
  }

  /// Every account a drawer-only form may pay from: active, and never custody. The cash box is
  /// what the server falls back to, so it is the one «تلقائي» names.
  Future<void> _loadSpendable() async {
    if (!sl.isRegistered<GetTreasuryAccounts>()) return;

    final result = await sl<GetTreasuryAccounts>()(activeOnly: true);

    if (!mounted || widget.method != null) return;

    result.fold((_) {}, (list) {
      final spendable = [
        for (final account in list.accounts)
          if (account.isSpendable && account.isActive) account,
      ];
      final cashBox = [
        for (final account in spendable)
          if (account.kind == AccountKind.cash && account.isDefault) account.id,
      ].firstOrNull;

      setState(
        () => _options = AccountOptions(
          accounts: [
            for (final account in spendable)
              AccountOption(
                id: account.id,
                name: account.name,
                kindLabel: account.kindLabel,
                isDefault: account.isDefault,
              ),
          ],
          suggestedId: cashBox,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;

    if (options == null || options.accounts.isEmpty) return const SizedBox.shrink();

    final scheme = context.colorScheme;
    final suggested = [
      for (final account in options.accounts)
        if (account.id == options.suggestedId) account.name,
    ].firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            ChoiceChip(
              label: Text(suggested == null ? 'تلقائي' : 'تلقائي — $suggested'),
              selected: widget.value == null,
              onSelected: (_) => widget.onChanged(null),
            ),
            for (final account in options.accounts)
              ChoiceChip(
                label: Text(account.name),
                selected: widget.value == account.id,
                onSelected: (_) => widget.onChanged(account.id),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          widget.incoming ? 'أين نزل المال' : 'من أين خرج المال',
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
