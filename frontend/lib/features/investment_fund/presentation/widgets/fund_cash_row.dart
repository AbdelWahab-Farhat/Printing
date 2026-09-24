import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// سطرٌ في سجلّ الخزينة — قراءةُ دفتر الصندوق كما يقرأ أمينُ المخزن دفترَ رفّه.
///
/// على جهة القراءة: **ماذا حدث** ومن أين جاء المالُ أو إلى أين ذهب — «تحصيل مبيعات» فوق
/// «طلبية ORD-12 · محمد». وعلى الجهة الأخرى الرقمان بالترتيب الذي يُقرأ به دفتر: **كم، بإشارته**،
/// ثم **ما بقي في الخزينة بعده**. والإشارةُ هي المقصود: ألفٌ داخلٌ وألفٌ خارج رقمان مختلفان.
///
/// على شكل `LedgerRow` في المخازن — المرجعُ المقبول لسطر الدفتر — والوقتُ آخرُ ما يُقرأ، واليومُ
/// على الترويسة فوق مجموعته.
class FundCashRow extends StatelessWidget {
  const FundCashRow({required this.entry, this.onTap, super.key});

  final FundCashEntry entry;

  /// يفتح ما جاء منه المال — الطلبيةَ أو أمرَ الشراء أو المستثمر. `null` لصفٍّ لا بابَ له.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = entry.isInflow ? scheme.primary : scheme.error;
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Icon(_icon, size: 20.sp, color: tone),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.typeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (entry.description case final description? when description.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: quiet,
                      ),
                    ],
                    if (entry.notes case final notes? when notes.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(notes, style: quiet?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_amount د.ل',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text('الرصيد ${entry.balanceAfter.grouped} د.ل', style: quiet),
                ],
              ),
            ],
          ),
          if (entry.occurredAt case final at?) ...[
            SizedBox(height: 6.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(at.timeLabel, style: quiet),
            ),
          ],
        ],
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }

  /// `+800` / `−3,000` — **الإشارةُ لا تسقط أبداً**، وبعلامة الناقص الطباعية كسطر المخزن.
  String get _amount {
    final signed = entry.signedAmount;

    return signed.startsWith('-') ? '−${signed.substring(1).grouped}' : '+${signed.grouped}';
  }

  /// ما يُعرَف به نوعُ الحركة قبل أن يُقرأ — والنوعُ الذي لا يعرفه هذا الإصدار لا يُدّعى له شكل.
  IconData get _icon => switch (entry.type) {
    'deposit' => AppIcons.fundDeposit,
    'purchase' => AppIcons.purchaseOrders,
    'expense' => AppIcons.expense,
    'sale_proceeds' => AppIcons.payment,
    'stock_sold_to_press' => AppIcons.printedProduct,
    'profit_payout' || 'company_payout' || 'capital_return' => AppIcons.fundWithdraw,
    'legacy_transfer' => AppIcons.investorDeals,
    'write_off_covered_by_company' => AppIcons.writeOff,
    _ => AppIcons.more,
  };
}
