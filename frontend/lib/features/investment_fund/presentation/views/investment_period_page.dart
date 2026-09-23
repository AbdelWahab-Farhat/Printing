import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/arabic_counts.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/period_orders_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_figures.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// شاشةُ الفترة الواحدة — **ما ربحه المستثمرون فيها، طلبيةً طلبية**.
///
/// سجلُّ الفترات يقول «كم ربحت الفترة»، وهذه تقول **من أين جاء ذلك الرقم ومن أخذه**: كلُّ طلبيةٍ
/// أعطت، وتحتها نصيبُ كلِّ شريك منها.
///
/// **والأرقامُ صفوفُ الدفتر نفسُها التي قُبض بها.** الفترةُ المغلقة وُزّع مالُها بأرقامٍ مُعلنة،
/// وإعادةُ اشتقاقها من الـFIFO بعد سنةٍ — بدفترٍ تحرّكت طبقاتُه — كانت تُظهر غيرَ ما دخل الجيوب.
class InvestmentPeriodPage extends StatelessWidget {
  const InvestmentPeriodPage({required this.periodId, this.periodCode, super.key});

  final int periodId;

  /// يُعرض في الشريط ريثما تصل الفترة، حين فُتحت الشاشة من صفٍّ يعرف رمزَها.
  final String? periodCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PeriodOrdersCubit(getOrders: sl())..load(periodId),
      child: Scaffold(
        appBar: AppBar(
          title: Text(periodCode == null ? 'الفترة' : 'الفترة $periodCode'),
        ),
        body: BlocBuilder<PeriodOrdersCubit, PeriodOrdersState>(
          builder: (context, state) => switch (state) {
            PeriodOrdersLoading() => const Center(child: CircularProgressIndicator()),
            PeriodOrdersFailure(:final failure) => _Retry(
              message: failure.message,
              periodId: periodId,
            ),
            PeriodOrdersLoaded(:final held) => RefreshIndicator(
              onRefresh: () => context.read<PeriodOrdersCubit>().load(periodId),
              child: _Body(held: held),
            ),
          },
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.periodId});

  final String message;
  final int periodId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
            SizedBox(height: 16.h),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<PeriodOrdersCubit>().load(periodId),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.held});

  final PeriodOrders held;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        _Header(period: held.period),
        SizedBox(height: 20.h),
        _Pool(totals: held.totals),
        if (held.investors.isNotEmpty) ...[
          SizedBox(height: 24.h),
          _Ledger(investors: held.investors),
        ],
        SizedBox(height: 28.h),
        Text(
          'الطلبيات',
          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.h),
        if (held.orders.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'لم تُعطِ طلبيةٌ ربحاً للمستثمرين في هذه الفترة بعد',
              style: context.textTheme.bodyMedium,
            ),
          )
        else
          // البابُ إلى الطلبية نفسها، ولا يعود منه شيء: ما تعرضه هذه الشاشة صفوفُ دفترٍ لا
          // تغيّرها شاشةُ الطلبية.
          for (final order in held.orders)
            PeriodOrderCard(
              key: ValueKey(order.orderId),
              order: order,
              onTap: () => context.push(Routes.order(order.orderId)),
            ),
      ],
    );
  }
}

/// ترويسةُ الفترة: نافذتُها وحالتُها، وأرقامُها المجمّدة إن أُقفلت.
class _Header extends StatelessWidget {
  const _Header({required this.period});

  final FundPeriod period;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفترة ${period.code} — ${period.statusLabel}',
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10.h),
          Text(
            '${period.startsOn} ← ${period.endsOn}',
            style: context.textTheme.bodyMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            'حصة المستثمرين ${period.investorProfitSharePercent}%',
            style: context.textTheme.bodyMedium,
          ),
          if (period.owedOrders case final owed? when owed > 0) ...[
            SizedBox(height: 8.h),
            Text('تنتظر ${ordersCount(owed)}', style: context.textTheme.bodyMedium),
          ],
          if (period.overrideReason case final reason?) ...[
            SizedBox(height: 8.h),
            Text('أُقفلت بتجاوز: $reason', style: context.textTheme.bodyMedium),
          ],
          if (period.netProfit != null) ...[
            SizedBox(height: 12.h),
            PeriodFigures(period: period),
          ],
        ],
      ),
    );
  }
}

/// ما أخذه المستثمرون من طلبيات هذه الفترة — مجموعُ صفوفها هي لا رقمٌ ثانٍ.
///
/// **ويفترق عن «للمستثمرين» في أرقام الإقفال عن قصد**: ذاك ما أُفرِج عنه يوم أُقفلت، وهذا ما
/// قُيِّد طلبيةً طلبية. يتساويان في الحال السويّة، ويفترقان حين تحمل الفترةُ خسارةً شُطبت من
/// رأس المال.
class _Pool extends StatelessWidget {
  const _Pool({required this.totals});

  final PeriodOrdersTotals totals;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isNegative = totals.investorsTotal.startsWith('-');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            'ربح المستثمرين من طلبيات الفترة',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          SizedBox(height: 6.h),
          Text(
            '${totals.investorsTotal.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.headlineSmall?.copyWith(
              color: isNegative ? scheme.error : scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'من ${totals.orders} طلبية',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

/// سجلُّ ربح المستثمرين في الفترة — كلُّ شريكٍ ومجموعُ ما أخذه من طلبياتها.
class _Ledger extends StatelessWidget {
  const _Ledger({required this.investors});

  final List<PeriodInvestorShare> investors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'سجل ربح المستثمرين',
          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.h),
        for (final share in investors) _LedgerRow(share: share),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.share});

  final PeriodInvestorShare share;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isNegative = share.amount.startsWith('-');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(child: Text(share.name, style: context.textTheme.bodyMedium)),
          SizedBox(width: 8.w),
          Text(
            '${share.amount.grouped} د.ل',
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
