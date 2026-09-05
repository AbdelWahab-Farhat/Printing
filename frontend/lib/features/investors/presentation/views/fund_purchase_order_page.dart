import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_picker_sheet.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Financing a purchase order: which of its lines, who is in it, and what each man put in.
///
/// **The deal is born here, from the order it is about.** Its materials are the order's own
/// lines, the claim on each is made by the server, and the percentages are the amounts — so what
/// is left to type is a name and a column of money.
///
/// **One order may carry several deals, one per group of lines**, because the claim the receipt
/// reads is per line. A line another deal already took is shown and locked rather than hidden:
/// «مموَّل ضمن D3» answers the question before it is asked.
///
/// Pops with the deal the server stored.
class FundPurchaseOrderPage extends StatefulWidget {
  const FundPurchaseOrderPage({required this.order, super.key});

  final PurchaseOrder order;

  @override
  State<FundPurchaseOrderPage> createState() => _FundPurchaseOrderPageState();
}

/// The least a man may come into a deal with — the server's own floor, said in the box he is
/// typing into rather than after he presses save.
///
/// **A floor on the stake, not on the money.** A hundred dinars buys a share that rounds to
/// noise in every split it touches, and it buys a row in the ledger, a line on the deal screen
/// and a partner to answer to at closing.
const _minimumStake = 1000;

class _FundPurchaseOrderPageState extends State<FundPurchaseOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _sharePercent = TextEditingController();

  final _funders = <({Investor investor, TextEditingController amount})>[];

  /// The shelves this deal is taking. Starts as everything nobody has claimed.
  late final Set<int> _chosen = {
    for (final line in widget.order.items)
      if (_dealOn(line.stockItemId) == null) line.stockItemId,
  };

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // **The company default, shown rather than implied.** Left empty the server would seed the
    // same figure, but the number a deal is struck on is not something to discover afterwards —
    // and it stays editable, because renegotiating one shipment is a real thing.
    _sharePercent.text = trimDecimals(
      widget.order.defaultInvestorProfitSharePercent ?? '',
    );
  }

  @override
  void dispose() {
    _sharePercent.dispose();
    for (final row in _funders) {
      row.amount.dispose();
    }
    super.dispose();
  }

  /// The deal already funding one line, or null while it is free.
  PurchaseOrderFunding? _dealOn(int stockItemId) {
    for (final funding in widget.order.investorFunding) {
      if (funding.stockItemIds.contains(stockItemId)) return funding;
    }

    return null;
  }

  double _costOf(PurchaseOrderItem line) =>
      double.tryParse(line.finalTotalCost ?? '0') ?? 0;

  /// What the chosen lines cost landed — the figure the money is held up against.
  double get _chosenCost => widget.order.items
      .where((line) => _chosen.contains(line.stockItemId))
      .fold(0, (sum, line) => sum + _costOf(line));

  double _amountOf(({Investor investor, TextEditingController amount}) row) =>
      double.tryParse(Validators.toWesternDigits(row.amount.text.trim())) ?? 0;

  double get _funded => _funders.fold(0, (sum, row) => sum + _amountOf(row));

  /// His share of the investors' half — the amount he put in, as a percentage of the pot.
  ///
  /// **A preview of the server's own arithmetic**, not a second opinion: the deal is stored with
  /// percentages worked out from these same amounts. Shown live because «كم صارت نسبتي؟» is the
  /// question being answered while the number is typed.
  double _percentOf(({Investor investor, TextEditingController amount}) row) {
    final total = _funded;

    return total <= 0 ? 0 : _amountOf(row) / total * 100;
  }

  Future<void> _addInvestor() async {
    final investor = await showInvestorPicker(context: context);

    if (investor == null || !mounted) return;

    setState(() {
      if (!_funders.any((row) => row.investor.id == investor.id)) {
        _funders.add((investor: investor, amount: TextEditingController()));
      }
    });
  }

  /// Drops a partner, and disposes his box **after** the frame that unmounts it — the trap the
  /// deal form documents.
  void _remove(({Investor investor, TextEditingController amount}) row) {
    setState(() => _funders.remove(row));

    WidgetsBinding.instance.addPostFrameCallback((_) => row.amount.dispose());
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_chosen.isEmpty) {
      context.showError('اختر بنداً واحداً على الأقل تموّله الصفقة');

      return;
    }

    if (_funders.isEmpty) {
      context.showError('أضف مستثمراً واحداً على الأقل');

      return;
    }

    // **The ceiling is what the goods cost.** Money beyond it buys no stock and would earn on a
    // shipment it did not pay for. The server refuses it too — said here first, because a filled
    // form answered with a refusal is a wasted minute.
    if (_funded - _chosenCost > 0.005) {
      context.showError('التمويل أكبر من تكلفة البنود المختارة');

      return;
    }

    setState(() => _saving = true);

    final result = await sl<FundPurchaseOrder>()(widget.order.id, <String, dynamic>{
      if (_sharePercent.text.trim().isNotEmpty)
        'investor_profit_share_percent': Validators.toWesternDigits(
          _sharePercent.text.trim(),
        ),
      'stock_item_ids': _chosen.toList(),
      'investors': [
        for (final row in _funders)
          <String, dynamic>{
            'investor_id': row.investor.id,
            'amount': Validators.toWesternDigits(row.amount.text.trim()),
          },
      ],
    });

    if (!mounted) return;

    setState(() => _saving = false);

    result.fold(
      (failure) => context.showError(failure.message),
      (deal) {
        // `Navigator`, not `context.pop`: go_router asserts when there is nothing to pop.
        Navigator.of(context).pop(deal);
        context.showSuccess('تم تمويل الأمر — الصفقة ${deal.code} مفتوحة');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تمويل أمر الشراء')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
            children: [
              const _SectionTitle('البنود التي تموّلها هذه الصفقة'),
              SizedBox(height: 8.h),
              for (final line in widget.order.items)
                _LineChoice(
                  line: line,
                  cost: _costOf(line),
                  takenBy: _dealOn(line.stockItemId),
                  chosen: _chosen.contains(line.stockItemId),
                  onToggle: () => setState(() {
                    _chosen.contains(line.stockItemId)
                        ? _chosen.remove(line.stockItemId)
                        : _chosen.add(line.stockItemId);
                  }),
                ),
              SizedBox(height: 20.h),

              _Coverage(cost: _chosenCost, funded: _funded),
              SizedBox(height: 24.h),

              const _SectionTitle('المستثمرون'),
              SizedBox(height: 8.h),
              for (final row in _funders)
                _FunderRow(
                  investor: row.investor,
                  amount: row.amount,
                  percent: _percentOf(row),
                  onChanged: () => setState(() {}),
                  onRemove: () => _remove(row),
                ),
              SizedBox(height: 4.h),
              AppButton.outlined(label: 'إضافة مستثمر', onPressed: _addInvestor),
              SizedBox(height: 24.h),

              const _SectionTitle('الصفقة'),
              SizedBox(height: 8.h),
              AppTextField(
                controller: _sharePercent,
                label: 'نسبة المستثمرين من الربح',
                prefixIcon: AppIcons.report,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]')),
                ],
                suffix: Text('%', style: context.textTheme.bodyLarge),
                validator: Validators.optional(
                  Validators.decimal(allowZero: false, max: 100),
                ),
              ),
              SizedBox(height: 28.h),

              AppButton(
                label: 'تمويل وفتح الصفقة',
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

/// One line of the order, and whether this deal is taking it.
///
/// A line another deal already took is drawn locked and named, rather than left out: «مموَّل ضمن
/// D3» is the answer to why it cannot be chosen, and hiding it would leave the question standing.
class _LineChoice extends StatelessWidget {
  const _LineChoice({
    required this.line,
    required this.cost,
    required this.takenBy,
    required this.chosen,
    required this.onToggle,
  });

  final PurchaseOrderItem line;
  final double cost;
  final PurchaseOrderFunding? takenBy;
  final bool chosen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final taken = takenBy != null;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: taken ? null : onToggle,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: chosen && !taken
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              // Material's own box, disabled on a line another deal took — a control that reads
              // «not yours to choose» without a new icon being invented for it.
              Checkbox(
                value: chosen && !taken,
                onChanged: taken ? null : (_) => onToggle(),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.stockItem?.displayName ?? 'مادة #${line.stockItemId}',
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      taken
                          ? 'مموَّل ضمن ${takenBy!.code}'
                          : '${groupedDecimal(line.quantityOrdered)} × ${groupedDecimal(line.finalUnitCost ?? '0')}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${groupedDecimal(cost.toStringAsFixed(2))} د.ل',
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: taken ? scheme.onSurfaceVariant : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the chosen lines cost, what the partners covered, and the company's own stake.
///
/// **The company is a partner for the remainder** — the owner's rule: «الشركة لما تحط فلوس تكون
/// كأنها طرف تاني». So beside each amount stands the fraction of the goods it buys, because that
/// fraction is what the deal will be split by: three men with 3,000 in a 20,000 lorry own 15% of
/// it, and are paid half of what that 15% earns. The server derives the same two figures from the
/// same amounts and freezes them with the deal; this is a preview of its arithmetic, not a second
/// opinion.
class _Coverage extends StatelessWidget {
  const _Coverage({required this.cost, required this.funded});

  final double cost;
  final double funded;

  /// A share of the cost as a percentage, or nothing when there is no cost to be a share of.
  double? _fractionOf(double amount) => cost > 0 ? amount / cost * 100 : null;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final remainder = cost - funded;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _CoverageRow(label: 'تكلفة ما اخترته', value: cost),
          SizedBox(height: 8.h),
          _CoverageRow(
            label: 'المموَّل من المستثمرين',
            value: funded,
            percent: funded > 0 ? _fractionOf(funded) : null,
          ),
          if (remainder.abs() > 0.005) ...[
            Divider(height: 22.h),
            _CoverageRow(
              label: remainder > 0 ? 'الباقي على الشركة' : 'زائد عن التكلفة',
              value: remainder.abs(),
              percent: remainder > 0 ? _fractionOf(remainder) : null,
              tone: remainder > 0 ? scheme.primary : scheme.error,
            ),
          ],
        ],
      ),
    );
  }
}

/// One line of the coverage: the amount, and when it is a stake in the goods, its fraction.
class _CoverageRow extends StatelessWidget {
  const _CoverageRow({required this.label, required this.value, this.percent, this.tone});

  final String label;
  final double value;
  final double? percent;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800, color: tone);

    return Row(
      children: [
        Expanded(child: Text(label, style: context.textTheme.bodyLarge)),
        if (percent != null) ...[
          Text('${trimDecimals(percent!.toStringAsFixed(4))}%', style: style),
          SizedBox(width: 12.w),
        ],
        Text('${groupedDecimal(value.toStringAsFixed(2))} د.ل', style: style),
      ],
    );
  }
}

/// One partner: what he is putting in, and the share of the investors' half it buys him.
class _FunderRow extends StatelessWidget {
  const _FunderRow({
    required this.investor,
    required this.amount,
    required this.percent,
    required this.onChanged,
    required this.onRemove,
  });

  final Investor investor;
  final TextEditingController amount;
  final double percent;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 4.w, 12.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    investor.name,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${trimDecimals(percent.toStringAsFixed(4))}%',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                IconButton(
                  tooltip: 'إزالة',
                  icon: Icon(AppIcons.close, size: 20.r),
                  onPressed: onRemove,
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: AppTextField(
                controller: amount,
                label: 'ما وضعه',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]')),
                ],
                suffix: Text('د.ل', style: context.textTheme.bodyLarge),
                onChanged: (_) => onChanged(),
                validator: Validators.compose([
                  Validators.required,
                  Validators.decimal(allowZero: false),
                  _atLeastTheMinimum,
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «أقل مبلغ يدخل به مستثمر صفقةً هو 1000 د.ل» — the server's wording, so the same refusal reads
/// the same whichever side catches it.
String? _atLeastTheMinimum(String? input) {
  final value = double.tryParse(Validators.toWesternDigits(input?.trim() ?? ''));

  // A number that will not parse is somebody else's complaint — `decimal` above already made it.
  if (value == null || value >= _minimumStake) return null;

  return 'أقل مبلغ يدخل به مستثمر صفقةً هو $_minimumStake د.ل';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
