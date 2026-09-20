import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شراءُ أمرِ شراءٍ بمال الصندوق.
///
/// **نصفُ شاشةِ التمويل القديمة، لأن نصفَ أسئلتها لم يعد له معنى.** تلك تسأل: من الممولون، وكم
/// وضع كلٌّ منهم، وبأيّ نسبٍ يُقسَّم، وكم نصيبُ الشركة فيما لم تغطِّه أموالهم. وفي الصندوق
/// الجوابُ واحدٌ لكلّها: **الصندوقُ يدفع الثمن كلَّه**، والنسبُ وحداتٌ تُقرأ لكل فترة، ولا صفقةَ
/// تُولد أصلاً.
///
/// فما بقي سؤالان: أيَّ الرفوف يأخذ، وهل في الدرج ما يكفي.
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

  FundStanding? _standing;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<GetFundStanding>()();

    if (!mounted) return;

    setState(() {
      _loading = false;
      _standing = result.fold((_) => null, (standing) => standing);
    });
  }

  /// تكلفةُ ما اختير — بالتكلفة الواصلة، وهي نفسُها ما سيخرج من الخزينة.
  String get _cost {
    var total = 0.0;

    for (final line in widget.order.items) {
      if (_chosen.contains(line.stockItemId)) {
        total += double.tryParse(line.finalTotalCost ?? line.baseTotalCost ?? '0') ?? 0;
      }
    }

    return total.toStringAsFixed(2);
  }

  Future<void> _buy() async {
    if (_chosen.isEmpty) {
      context.showError('اختر رفّاً واحداً على الأقل');

      return;
    }

    setState(() => _saving = true);

    final result = await safeRequest<void>(
      () => sl<Dio>().post(
        InvestmentEndpoints.fundPurchase(widget.order.id),
        data: {'stock_item_ids': _chosen.toList()},
      ),
      parse: (_) {},
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
    final cash = _standing?.valuation.cash ?? '0';
    final enough = (double.tryParse(cash) ?? 0) >= (double.tryParse(_cost) ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('شراء بمال الصندوق')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              children: [
                _Figure(label: 'نقد الصندوق', amount: cash),
                _Figure(label: 'تكلفة ما اخترت', amount: _cost, emphasis: true),
                if (!enough) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: context.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'نقد الصندوق لا يكفي — الباقي بضاعةٌ ومستحقّاتٌ لم تُحصَّل',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
                Text(
                  'الرفوف',
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8.h),
                for (final line in widget.order.items)
                  CheckboxListTile(
                    value: _chosen.contains(line.stockItemId),
                    title: Text(line.title),
                    subtitle: Text(
                      '${line.totalCostLabel} د.ل',
                      textDirection: TextDirection.ltr,
                    ),
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        _chosen.add(line.stockItemId);
                      } else {
                        _chosen.remove(line.stockItemId);
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

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.amount, this.emphasis = false});

  final String label;
  final String amount;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
          Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
