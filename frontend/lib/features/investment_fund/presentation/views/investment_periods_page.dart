import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_periods_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_figures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// سجلُّ الفترات — وهو الذي يحلّ محلّ «قائمة الصفقات».
///
/// **المغلقةُ تحمل أرقامها مجمّدةً**: ما باعت، وما ربحت، وكم ذهب للمستثمرين وكم للشركة. وهي
/// أرقامٌ لا تُعاد قراءتُها من الدفاتر بعد اليوم — بها وُزّع المال، ولو أُعيد الحسابُ بعد سنةٍ
/// بدفترٍ تحرّك لأظهر رقماً غير الذي قُبض به.
class InvestmentPeriodsPage extends StatelessWidget {
  const InvestmentPeriodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvestmentPeriodsCubit(getPeriods: sl())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('سجل الفترات')),
        body: BlocBuilder<InvestmentPeriodsCubit, InvestmentPeriodsState>(
          builder: (context, state) => switch (state) {
            InvestmentPeriodsLoading() => const Center(child: CircularProgressIndicator()),
            InvestmentPeriodsFailure(:final failure) => Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    AppButton(
                      label: 'إعادة المحاولة',
                      onPressed: () => context.read<InvestmentPeriodsCubit>().load(),
                    ),
                  ],
                ),
              ),
            ),
            InvestmentPeriodsLoaded(:final periods) when periods.isEmpty => Center(
              child: Text('لم تُفتح فترةٌ بعد', style: context.textTheme.bodyMedium),
            ),
            InvestmentPeriodsLoaded(:final periods) => RefreshIndicator(
              onRefresh: () => context.read<InvestmentPeriodsCubit>().load(),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                itemCount: periods.length,
                itemBuilder: (_, index) => _PeriodCard(period: periods[index]),
              ),
            ),
          },
        ),
      ),
    );
  }
}

/// صفُّ فترة — **وهو بابٌ يُفتح**، لأن الرقم على وجهه لا يقول من صنعه.
///
/// «للمستثمرين ٩٠٥» يفتح سؤالاً ولا يجيبه: أيُّ طلبيةٍ أعطته، وكم أخذ كلُّ شريك. فالنقرةُ تُفضي
/// إلى تفصيله طلبيةً طلبية.
class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period});

  final FundPeriod period;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isOpen = period.status == 'open';
    final radius = BorderRadius.circular(16.r);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: isOpen ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => context.push(Routes.investmentPeriod(period.id), extra: period.code),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        period.code,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(period.statusLabel, style: context.textTheme.bodyMedium),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '${period.startsOn} ← ${period.endsOn}',
                  style: context.textTheme.bodyMedium,
                ),
                if (period.endsSettlementCycle) ...[
                  SizedBox(height: 8.h),
                  Text('تُغلق دورة تسوية', style: context.textTheme.bodyMedium),
                ],
                if (period.netProfit != null) ...[
                  SizedBox(height: 12.h),
                  PeriodFigures(period: period),
                ],
                if (period.overrideReason case final reason?) ...[
                  SizedBox(height: 12.h),
                  Text('أُقفلت بتجاوز: $reason', style: context.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
