import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أرقامُ فترةٍ أُقفلت — مجمّدةً كما وُزّع بها المال.
///
/// **ولا تُرسم أصفارٌ مكان «لم يُحسب بعد».** الفترةُ المفتوحة لا أرقامَ إقفالٍ لها، فتَرسم هذه
/// لا شيء بدل أن تقول إنها لم تبع ولم تربح.
///
/// تُرسم في موضعين — صفِّ السجلّ وترويسةِ الفترة — ونسخةٌ ثانية منها كانت تعني رقماً يُضاف في
/// شاشةٍ ويُنسى في الأخرى.
class PeriodFigures extends StatelessWidget {
  const PeriodFigures({required this.period, super.key});

  final FundPeriod period;

  @override
  Widget build(BuildContext context) {
    final profit = period.netProfit;

    if (profit == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Figure(label: 'المبيعات', amount: period.salesRevenue ?? '0'),
        _Figure(label: 'صافي الربح', amount: profit),
        _Figure(label: 'للمستثمرين', amount: period.investorsPool ?? '0'),
        _Figure(label: 'للشركة', amount: period.companyShare ?? '0'),
        _Figure(label: 'البضاعة عند الإقفال', amount: period.closingStockCost ?? '0'),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
          Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
