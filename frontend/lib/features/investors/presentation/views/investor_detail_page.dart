import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/wallet_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One investor: what his money is doing, and the moves that put it there.
class InvestorDetailPage extends StatelessWidget {
  const InvestorDetailPage({super.key, required this.investorId});

  final int investorId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvestorDetailCubit>(
      create: (_) => sl<InvestorDetailCubit>()..load(investorId),
      child: _InvestorDetailView(investorId: investorId),
    );
  }
}

class _InvestorDetailView extends StatelessWidget {
  const _InvestorDetailView({required this.investorId});

  final int investorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستثمر')),
      body: BlocBuilder<InvestorDetailCubit, InvestorDetailState>(
        builder: (context, state) => switch (state) {
          InvestorDetailLoading() => const Center(child: CircularProgressIndicator()),
          InvestorDetailFailure(:final failure) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(failure.message, textAlign: TextAlign.center),
            ),
          ),
          InvestorDetailLoaded(:final investor) => _Body(investor: investor),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.investor});

  final Investor investor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<InvestorDetailCubit>();
    final balances = investor.balances;
    final canRecord = sl<Session>().can(AppPermission.recordInvestorMoney);

    return RefreshIndicator(
      onRefresh: () => cubit.load(investor.id),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            investor.name,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            [investor.code, if (investor.phone != null) investor.phone!].join(' · '),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),

          if (balances != null) ...[
            _Money(
              label: 'رصيد المحفظة',
              amount: balances.wallet.capital,
              caption: 'متاح للتمويل أو للسحب',
            ),
            const SizedBox(height: 12),
            _Money(
              label: 'أرباح متاحة للسحب',
              amount: balances.wallet.profit,
              caption: 'أُفرجت عنها بإقفال صفقة',
            ),
            const SizedBox(height: 20),
            Text(
              'في الصفقات',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (balances.deals.isEmpty)
              Text('لا مال له في أي صفقة', style: theme.textTheme.bodyMedium)
            else
              ...balances.deals.map(
                (pots) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DealRow(pots: pots),
                ),
              ),
          ],

          const SizedBox(height: 28),
          if (canRecord)
            AppButton(
              label: 'تسجيل حركة مالية',
              onPressed: () => showWalletEntrySheet(
                context: context,
                cubit: cubit,
                investor: investor,
                // Only deals he is actually in can take his money, and the list he picks from
                // says so — the server refuses anything else, and this saves him the refusal.
                deals: <({int id, String label})>[
                  for (final DealPots pots in balances?.deals ?? const <DealPots>[])
                    (id: pots.investorDealId, label: 'صفقة #${pots.investorDealId}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Money extends StatelessWidget {
  const _Money({required this.label, required this.amount, this.caption});

  final String label;
  final String amount;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${amount.grouped} د.ل',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _DealRow extends StatelessWidget {
  const _DealRow({required this.pots});

  final DealPots pots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoss = pots.profit.startsWith('-');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('صفقة #${pots.investorDealId}', style: theme.textTheme.bodyLarge),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${pots.capital.grouped} د.ل', style: theme.textTheme.bodyLarge),
                Text(
                  '${pots.profit.grouped} د.ل',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLoss ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
