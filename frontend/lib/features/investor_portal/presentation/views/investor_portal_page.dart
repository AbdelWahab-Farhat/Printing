import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:dayaa/features/investor_portal/presentation/viewmodel/investor_portal_cubit.dart';
import 'package:dayaa/features/investor_portal/presentation/widgets/investor_deal_card.dart';
import 'package:dayaa/features/investor_portal/presentation/widgets/investor_money_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      appBar: AppBar(title: const Text('حسابي')),
      body: BlocBuilder<InvestorPortalCubit, InvestorPortalState>(
        builder: (context, state) => switch (state) {
          InvestorPortalInitial() ||
          InvestorPortalLoading() => const Center(child: CircularProgressIndicator()),
          InvestorPortalFailure(:final failure) => _Failure(message: failure.message),
          InvestorPortalLoaded(:final portfolio) => _Portfolio(portfolio: portfolio),
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
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => context.read<InvestorPortalCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            portfolio.investor.name,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(portfolio.investor.code, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),

          // **The two figures he came for**, and they are two rather than one on purpose: what
          // is committed to goods and what is sitting free are different answers to «كم مالي
          // لديكم؟», and a single total would answer neither.
          InvestorMoneyTile(
            label: 'رأس مالي في الصفقات',
            amount: portfolio.capitalInDeals,
            caption: 'يموّل بضاعة على الرفّ الآن',
            emphasis: true,
          ),
          const SizedBox(height: 12),
          InvestorMoneyTile(
            label: 'رصيد محفظتي',
            amount: portfolio.capitalInWallet,
            caption: 'متاح للتمويل أو للسحب',
          ),
          const SizedBox(height: 20),

          Text('الأرباح', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // Two profit figures, never merged. One is earned and still riding on deals that have
          // not finished; the other has been released and can be asked for. A single number
          // would either promise money that is not available or hide money already made.
          InvestorMoneyTile(
            label: 'أرباحي حتى الآن',
            amount: portfolio.profitInDeals,
            caption: 'من صفقات ما زالت مفتوحة — تُصرف عند إقفالها',
            emphasis: true,
          ),
          const SizedBox(height: 12),
          InvestorMoneyTile(
            label: 'أرباح متاحة للسحب',
            amount: portfolio.profitAvailable,
            caption: 'من صفقات أُقفلت',
          ),
          const SizedBox(height: 12),
          InvestorMoneyTile(
            label: 'أرباح مسحوبة',
            amount: portfolio.profitWithdrawn,
            caption: 'ما استلمتَه فعلاً',
          ),

          const SizedBox(height: 24),
          Text(
            'صفقاتي',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          if (portfolio.deals.isEmpty)
            Text('لا توجد صفقات بعد', style: theme.textTheme.bodyMedium)
          else
            ...portfolio.deals.map(
              (deal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InvestorDealCard(deal: deal),
              ),
            ),

          const SizedBox(height: 28),
          // Full width with small margins — the standing rule for an action button here.
          AppButton.outlined(
            label: 'تحديث',
            onPressed: () => context.read<InvestorPortalCubit>().refresh(),
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<InvestorPortalCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}
