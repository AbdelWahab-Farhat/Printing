import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/fund_detail_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_total_card.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_order_card.dart';
import 'package:dayaa/features/investment_fund/usecases/fund_breakdown_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// الأرباحُ المستحقّة للمستثمرين — «الطلبيات، وربح كل واحدة منها».
///
/// الرقمُ نصفان، ولكلٍّ جوابُه:
///
/// - **لم يُفرج عنها بعد** — ربحُ طلبياتٍ في فترةٍ لم تُقفَل، أو حجزت بوّابةُ التحصيل ربحَها.
///   طلبيةً طلبية ببطاقة شاشة الفترة نفسِها، وتحت كلٍّ نصيبُ كلِّ شريك.
/// - **أُفرج عنها ولم تُسحب** — في محافظ أصحابها. لكلِّ صاحبٍ رصيدُه، **لا طلبيته**: الإفراجُ
///   لفترةٍ كاملة والسحبُ من المحفظة كلِّها، فنسبةُ الباقي إلى طلبيةٍ قسمةٌ تُخترع.
///
/// والمجموعُ ومجموعا النصفين من الخادم، لا جمعٌ هنا.
class FundProfitOwedPage extends StatelessWidget {
  const FundProfitOwedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FundDetailCubit<FundProfitOwed>(() => sl<GetFundProfitOwed>()())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('أرباح مستحقّة للمستثمرين')),
        body: FundDetailBody<FundProfitOwed>(
          builder: (context, owed) {
            final wallets = owed.inWallets;
            final unreleased = owed.unreleased;
            final nothing = wallets.investors.isEmpty &&
                unreleased.orders.isEmpty &&
                unreleased.adjustments.isEmpty;

            return [
              FundTotalCard(label: 'المجموع', amount: owed.total),
              if (nothing) const FundEmptyLine('لا أرباح مستحقّة الآن'),
              if (wallets.investors.isNotEmpty) ...[
                SizedBox(height: 24.h),
                FundSectionTitle(
                  title: 'أُفرج عنها ولم تُسحب',
                  amount: '${wallets.total.grouped} د.ل',
                ),
                for (final (index, share) in wallets.investors.indexed) ...[
                  if (index > 0) const FundHairline(),
                  _Line(label: share.name, amount: share.amount),
                ],
              ],
              if (unreleased.orders.isNotEmpty || unreleased.adjustments.isNotEmpty) ...[
                SizedBox(height: 24.h),
                FundSectionTitle(
                  title: 'لم يُفرج عنها بعد',
                  amount: '${unreleased.total.grouped} د.ل',
                ),
                SizedBox(height: 4.h),
                // البابُ إلى الطلبية نفسها، كما في شاشة الفترة.
                for (final order in unreleased.orders)
                  PeriodOrderCard(
                    key: ValueKey(order.orderId),
                    order: order,
                    onTap: () => context.push(Routes.order(order.orderId)),
                  ),
                for (final adjustment in unreleased.adjustments)
                  _Line(label: adjustment.label, amount: adjustment.amount),
              ],
            ];
          },
        ),
      ),
    );
  }
}

/// سطرُ اسمٍ ومبلغ — صاحبُ رصيدٍ في محفظته، أو مصروفٌ أكل من الربح. **بإشارته**: ما يُنقص
/// الربحَ يُقرأ بسالبه وبلون الخسارة، كسطر الشريك في بطاقة الطلبية.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isNegative = amount.startsWith('-');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
          SizedBox(width: 8.w),
          Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isNegative ? scheme.error : scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
