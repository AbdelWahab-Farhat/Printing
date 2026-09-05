import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:dayaa/features/investor_portal/presentation/viewmodel/investor_portal_cubit.dart';
import 'package:dayaa/features/investor_portal/presentation/widgets/investor_deal_card.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The investor's whole application.
///
/// **A `Scaffold` of its own, declared outside the staff shell.** The home route is branch zero
/// of the app's `StatefulShellRoute`, so reaching it builds the bottom navigation bar and the
/// drawer behind it — a shell full of screens an investor must not have. Putting conditions on
/// that screen would leave him one bug away from the staff app; there is nothing here to
/// navigate to at all.
class InvestorPortalPage extends StatelessWidget {
  const InvestorPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvestorPortalCubit>(
      create: (_) => sl<InvestorPortalCubit>()..load(),
      child: const _InvestorPortalView(),
    );
  }
}

class _InvestorPortalView extends StatelessWidget {
  const _InvestorPortalView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            icon: Icon(AppIcons.refresh),
            tooltip: 'تحديث',
            onPressed: () => context.read<InvestorPortalCubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<InvestorPortalCubit, InvestorPortalState>(
        builder: (context, state) => switch (state) {
          InvestorPortalInitial() ||
          InvestorPortalLoading() => const Center(child: CircularProgressIndicator()),
          InvestorPortalFailure(:final failure) => _FailureView(message: failure.message),
          InvestorPortalLoaded(:final portfolio) => RefreshIndicator(
            onRefresh: () => context.read<InvestorPortalCubit>().refresh(),
            child: _Portfolio(portfolio: portfolio),
          ),
        },
      ),
    );
  }
}

class _Portfolio extends StatelessWidget {
  const _Portfolio({required this.portfolio});

  final InvestorPortfolio portfolio;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListView(
      // `always`, so pull-to-refresh works on a portfolio short enough not to scroll.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        Text(
          portfolio.investor.name,
          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 2.h),
        Text(
          portfolio.investor.code,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 20.h),

        // **The two figures he came for**, and they are two rather than one on purpose: what is
        // committed to goods and what is sitting free are different answers to «كم مالي لديكم؟»,
        // and a single total would answer neither.
        InvestorMoneyTile(
          label: 'رأس مالي في الصفقات',
          amount: portfolio.capitalInDeals,
          caption: 'يموّل بضاعة على الرفّ الآن',
          emphasis: true,
        ),
        SizedBox(height: 12.h),
        InvestorMoneyTile(
          label: 'رصيد محفظتي',
          amount: portfolio.capitalInWallet,
          caption: 'متاح للتمويل أو للسحب',
        ),
        SizedBox(height: 24.h),

        Text(
          'الأرباح',
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8.h),

        // Three profit figures, never merged. One is earned and still riding on deals that have
        // not finished; one has been released and can be asked for; one he already has. A single
        // number would either promise money that is not available or hide money already made.
        InvestorMoneyTile(
          label: 'أرباحي حتى الآن',
          amount: portfolio.profitInDeals,
          caption: 'من صفقات ما زالت مفتوحة — تُصرف عند إقفالها',
          emphasis: true,
        ),
        SizedBox(height: 12.h),
        InvestorMoneyTile(
          label: 'أرباح متاحة للسحب',
          amount: portfolio.profitAvailable,
          caption: 'من صفقات أُقفلت',
        ),
        SizedBox(height: 12.h),
        InvestorMoneyTile(
          label: 'أرباح مسحوبة',
          amount: portfolio.profitWithdrawn,
          caption: 'ما استلمتَه فعلاً',
        ),
        SizedBox(height: 24.h),

        Text(
          'صفقاتي',
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8.h),

        if (portfolio.deals.isEmpty)
          Text(
            'لا توجد صفقات بعد',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          for (final deal in portfolio.deals)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: InvestorDealCard(deal: deal),
            ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: context.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            OutlinedButton.icon(
              onPressed: () => context.read<InvestorPortalCubit>().load(),
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
