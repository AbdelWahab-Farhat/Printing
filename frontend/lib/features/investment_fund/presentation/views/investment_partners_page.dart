import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_fund_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_partner_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شركاءُ الصندوق في فترتين — **من يقتسم ربحَ هذه الفترة، ومن يقتسم ربحَ التي تليها.**
///
/// قرارُ المالك 2026-09-23: «اريد عبدالرحمن فقط شريك هذه الفترة وينضمون للفترة التي تليها …
/// صفحة كاملة فيها خانتان: مستثمرين الفترة الحالية، مستثمرين الفترة القادمة». فمن اكتتب في
/// نافذة فترةٍ مالُه يعمل فيها ونصيبُه يبدأ من التالية — وسطرٌ واحد بـ«٠٫٠٠٪» كان يُقرأ عطباً.
///
/// **والقسمان من الخادم لا من الشاشة**: نسبةُ هذه الفترة `share_percent`، ونسبةُ التالية
/// `next_share_percent` — بكلّ الوحدات القائمة اليوم. الشاشةُ تفرز ولا تحسب.
class InvestmentPartnersPage extends StatelessWidget {
  const InvestmentPartnersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvestmentFundCubit(
        getStanding: sl(),
        openPeriod: sl(),
        closePeriod: sl(),
        deposit: sl(),
        withdraw: sl(),
        recordExpense: sl(),
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('شركاء الصندوق')),
        body: BlocBuilder<InvestmentFundCubit, InvestmentFundState>(
          builder: (context, state) => switch (state) {
            InvestmentFundLoading() => const Center(child: CircularProgressIndicator()),
            InvestmentFundFailure(:final failure) => _Retry(message: failure.message),
            InvestmentFundLoaded(:final standing) => RefreshIndicator(
              onRefresh: () => context.read<InvestmentFundCubit>().load(),
              child: _Partners(standing: standing),
            ),
          },
        ),
      ),
    );
  }
}

class _Partners extends StatelessWidget {
  const _Partners({required this.standing});

  final FundStanding standing;

  @override
  Widget build(BuildContext context) {
    final period = standing.period;

    final current = standing.investors
        .where((h) => !h.shareStartsNextPeriod && (double.tryParse(h.sharePercent) ?? 0) > 0)
        .toList();

    final next = standing.investors
        .where((h) => (double.tryParse(h.nextSharePercent) ?? 0) > 0)
        .toList()
      ..sort(
        (a, b) => (double.tryParse(b.nextSharePercent) ?? 0)
            .compareTo(double.tryParse(a.nextSharePercent) ?? 0),
      );

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        _Section(
          title: 'مستثمرو الفترة الحالية',
          subtitle: period == null
              ? 'لا فترة مفتوحة'
              : 'الفترة ${period.code} (${period.startsOn} ← ${period.endsOn}) — يقتسمون ربحها بهذه النسب',
          empty: 'لا شريك في هذه الفترة',
          children: [
            for (final holder in current)
              FundPartnerCard(holder: holder, percent: holder.sharePercent),
          ],
        ),
        SizedBox(height: 28.h),
        _Section(
          title: 'مستثمرو الفترة القادمة',
          // **تقديرٌ لا عهد** — ويقولها السطرُ قبل أن يُقرأ الرقمُ وعداً.
          subtitle: 'تبدأ بعد ${period?.endsOn ?? 'إقفال الفترة الحالية'} — نسبٌ بوحدات اليوم، '
              'تتغيّر إن اشترك أحدٌ أو استردّ قبل بدئها',
          empty: 'لا أحد بعد',
          children: [
            for (final holder in next)
              FundPartnerCard(
                holder: holder,
                percent: holder.nextSharePercent,
                badge: holder.shareStartsNextPeriod ? 'ينضمّ' : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.empty,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: 12.h),
        if (children.isEmpty)
          Text(empty, style: context.textTheme.bodyMedium)
        else
          ...children,
      ],
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message});

  final String message;

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
              onPressed: () => context.read<InvestmentFundCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}
