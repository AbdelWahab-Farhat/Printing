import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_purchase_chooser.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شراءُ أمرِ شراءٍ بمال الصندوق.
///
/// **نصفُ شاشةِ التمويل القديمة، لأن نصفَ أسئلتها لم يعد له معنى.** تلك تسأل: من الممولون، وكم
/// وضع كلٌّ منهم، وبأيّ نسبٍ يُقسَّم، وكم نصيبُ الشركة فيما لم تغطِّه أموالهم. وفي الصندوق
/// الجوابُ واحدٌ لكلّها: **الصندوقُ يدفع الثمن كلَّه**، والنسبُ وحداتٌ تُقرأ لكل فترة، ولا صفقةَ
/// تُولد أصلاً.
///
/// فما بقي ثلاثة: أيَّ الرفوف يأخذ، وهل في الدرج ما يكفي، وبكم تشتري المطبعةُ سادةَ كلِّ رفّ —
/// وهي أسئلةُ {@see FundPurchaseChooser}، تُسأل هنا وعلى نموذج أمرٍ يُنشأ الآن بالنصّ نفسه.
///
/// **وهذه الشاشةُ لأمرٍ قائم.** أمرٌ يُنشأ ليشتريه الصندوقُ يُموَّل في الضغطة التي أنشأته، من
/// صفِّ الصندوق على النموذج نفسِه؛ ويبقى هذا البابُ لمن أنشأ أمراً ثم قرّر.
class FundPurchasePage extends StatefulWidget {
  const FundPurchasePage({required this.order, super.key});

  final PurchaseOrder order;

  @override
  State<FundPurchasePage> createState() => _FundPurchasePageState();
}

class _FundPurchasePageState extends State<FundPurchasePage> {
  late final Set<int> _chosen = {
    for (final line in widget.order.items) line.stockItemId,
  };

  /// حقلُ سعر السادة لكل رفّ — واحدٌ لكل سطر، يعيش ما دامت الشاشة.
  ///
  /// **يُبنى للسطور كلِّها لا للمختار وحده**: بناؤه عند أول ظهورٍ كان يعني حقلاً جديداً — وقيمةً
  /// ضائعة — كلَّما رُفع الصحُّ عن رفٍّ ثم أُعيد.
  late final Map<int, TextEditingController> _prices = {
    for (final line in widget.order.items)
      line.stockItemId: TextEditingController(),
  };

  FundStanding? _standing;
  bool _loading = true;
  bool _saving = false;

  /// «سعر الصرف» on a dollar order — what the fund pays at in dinars, and what its goods keep
  /// when they arrive (USD-ACCOUNTS.md §٥). Opens on «سعر النظام»; an order funded before shows
  /// its own rate, which a second purchase keeps.
  late final _rate = TextEditingController(
    text: trimDecimals(widget.order.fundingRate ?? widget.order.systemUsdRate ?? ''),
  );

  bool get _inDollars => widget.order.isDollar;

  /// Funded before: the server keeps that rate, so it is shown and not asked.
  bool get _rateIsFixed => widget.order.fundingRate != null;

  /// The typed rate, or null when it is not a number above zero.
  double? get _rateValue {
    final parsed = double.tryParse(
      Validators.toWesternDigits(_rate.text.trim()).replaceAll(',', '.'),
    );

    return parsed == null || parsed <= 0 ? null : parsed;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _prices.values) {
      controller.dispose();
    }
    _rate.dispose();

    super.dispose();
  }

  Future<void> _load() async {
    final result = await sl<GetFundStanding>()();

    if (!mounted) return;

    setState(() {
      _loading = false;
      _standing = result.fold((_) => null, (standing) => standing);
      // الافتراضُ يصل مع اللوحة فيُملأ به ما لم يُكتب — ورفوفُ الكيلو وحدها.
      seedFundPrices(
        fallback: _standing?.defaultPlainSalePrice,
        shelves: _shelves,
        prices: _prices,
      );
    });
  }

  /// رفوفُ الأمر كما تُعرض وتُسعَّر.
  List<FundShelf> get _shelves => [
    for (final line in widget.order.items)
      (
        stockItemId: line.stockItemId,
        title: line.title,
        cost: _lineCost(line).toStringAsFixed(2),
        unitWire: line.unit,
        per: line.perUnitSuffix,
      ),
  ];

  /// What a line costs the fund, in dinars. On a dinar order, its landed cost. On a dollar one,
  /// its dollars at the rate and its share of the dinar costs planned on the order — spread by
  /// base cost, as the server spreads them (USD-ACCOUNTS.md §٥). The server's figure is the one
  /// charged; this one is shown beside the fund's cash.
  double _lineCost(PurchaseOrderItem line) {
    final landed = double.tryParse(line.finalTotalCost ?? line.baseTotalCost ?? '0') ?? 0;

    if (!_inDollars) return landed;

    final rate = _rateValue ?? 0;

    var bases = 0.0;
    for (final item in widget.order.items) {
      bases += double.tryParse(item.baseTotalCost ?? '0') ?? 0;
    }

    var dinarCosts = 0.0;
    for (final cost in widget.order.plannedCosts) {
      if (cost.currency != widget.order.currency) dinarCosts += double.tryParse(cost.amount) ?? 0;
    }

    final base = double.tryParse(line.baseTotalCost ?? '0') ?? 0;
    final share = bases <= 0 ? 0.0 : dinarCosts * base / bases;

    return landed * rate + share;
  }

  /// تكلفةُ ما اختير — بالتكلفة الواصلة، وهي نفسُها ما سيخرج من الخزينة.
  String get _cost {
    var total = 0.0;

    for (final line in widget.order.items) {
      if (_chosen.contains(line.stockItemId)) total += _lineCost(line);
    }

    return total.toStringAsFixed(2);
  }

  Future<void> _buy() async {
    if (_chosen.isEmpty) {
      context.showError('اختر رفّاً واحداً على الأقل');

      return;
    }

    if (_inDollars && _rateValue == null) {
      context.showError('اكتب سعر الصرف الذي يشتري به الصندوق');

      return;
    }

    setState(() => _saving = true);

    final result = await sl<BuyWithFund>()(
      widget.order.id,
      (stockItemIds: _chosen.toList(), printingSalePrices: fundPricesFrom(_prices, _chosen)),
      // Funded before, the server keeps that rate; sending it again would only say the same.
      rate: _inDollars && !_rateIsFixed
          ? Validators.toWesternDigits(_rate.text.trim()).replaceAll(',', '.')
          : null,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    result.fold(
      // نصُّ الخادم: «لا يكفي النقد» يقول الرقمين معاً، و«سطرٌ مموَّل» يسمّي من موّله.
      (failure) => context.showError(failure.message),
      (_) {
        Navigator.of(context).pop(true);
        context.showSuccess('اشترى الصندوقُ الأمر — خرج النقد وصارت رفوفُه من مواده');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شراء بمال الصندوق')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              children: [
                if (_inDollars) ...[
                  AppTextField(
                    key: const ValueKey('funding-rate'),
                    controller: _rate,
                    label: 'سعر الصرف (دينار لكل دولار)',
                    prefixIcon: AppIcons.exchange,
                    enabled: !_rateIsFixed,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _rateIsFixed
                        ? 'موّل الصندوقُ هذا الأمر من قبل بهذا السعر، فيبقى عليه'
                        : 'أمر بالدولار — يدفع الصندوق بالدينار بهذا السعر، وتبقى بضاعته عليه عند '
                              'الاستلام. مكتوبٌ فيه سعر النظام، وتقدر تغيّره',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
                FundPurchaseChooser(
                  cash: _standing?.valuation.cash,
                  cost: _cost,
                  shelves: _shelves,
                  chosen: _chosen,
                  prices: _prices,
                  onToggle: (stockItemId, chosen) => setState(() {
                    if (chosen) {
                      _chosen.add(stockItemId);
                    } else {
                      _chosen.remove(stockItemId);
                    }
                  }),
                ),
                SizedBox(height: 20.h),
                AppButton(
                  label: 'شراء بمال الصندوق',
                  isLoading: _saving,
                  onPressed: _saving ? null : _buy,
                ),
              ],
            ),
    );
  }
}
