import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deal_detail_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One deal: its terms, its goods, and what each investor stands at.
class InvestorDealDetailPage extends StatelessWidget {
  const InvestorDealDetailPage({super.key, required this.dealId});

  final int dealId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DealDetailCubit>(
      create: (_) => sl<DealDetailCubit>()..load(dealId),
      child: const _DealDetailView(),
    );
  }
}

class _DealDetailView extends StatelessWidget {
  const _DealDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصفقة')),
      body: BlocBuilder<DealDetailCubit, DealDetailState>(
        builder: (context, state) => switch (state) {
          DealDetailLoading() => const Center(child: CircularProgressIndicator()),
          DealDetailFailure(:final failure) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(failure.message, textAlign: TextAlign.center),
            ),
          ),
          DealDetailLoaded(:final deal) => _Body(deal: deal),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.deal});

  final InvestorDeal deal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<DealDetailCubit>();
    final canManage = sl<Session>().can(AppPermission.manageInvestors);
    final stock = deal.stock;
    final balances = deal.balances;

    return RefreshIndicator(
      onRefresh: () => cubit.load(deal.id),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            deal.name,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '${deal.code} · ${deal.statusLabel} · '
            'للمستثمرين ${trimDecimals(deal.investorProfitSharePercent)}% من الربح',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),

          if (stock != null) ...[
            Text('البضاعة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _Rows(
              rows: [
                ('وصل', groupedDecimal(stock.quantityReceived)),
                ('بِيع', groupedDecimal(stock.quantitySold)),
                ('متبقٍّ', groupedDecimal(stock.quantityRemaining)),
                ('هالك', groupedDecimal(stock.quantityDamaged)),
                ('عجز', groupedDecimal(stock.quantityShort)),
              ],
            ),
            const SizedBox(height: 20),
          ],

          if (balances != null) ...[
            Text('المال', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _Rows(
              rows: [
                ('رأس المال في الصفقة', '${balances.capital.grouped} د.ل'),
                ('أرباح المستثمرين حتى الآن', '${balances.profit.grouped} د.ل'),
              ],
            ),
            const SizedBox(height: 20),
          ],

          Text('المستثمرون', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final participant in deal.investors)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Participant(
                participant: participant,
                standing: balances?.perInvestor
                    .where((row) => row.investorId == participant.investorId)
                    .firstOrNull,
              ),
            ),

          const SizedBox(height: 28),
          if (canManage && deal.status == 'draft')
            AppButton(
              label: 'فتح الصفقة',
              onPressed: () async {
                final failure = await cubit.open(deal.id);
                if (!context.mounted) return;
                if (failure != null) {
                  context.showError(failure.message);
                } else {
                  context.showSuccess('فُتحت الصفقة — صارت شروطها نهائية');
                }
              },
            ),
          if (canManage && deal.status == 'open') ...[
            AppButton(
              label: 'إغلاق الصفقة وتسوية الحسابات',
              onPressed: () async {
                final failure = await cubit.closeDeal(deal.id);
                if (!context.mounted) return;
                if (failure != null) {
                  // The server refuses while stock is left or while an order that took this
                  // deal's goods has not reached the customer, and names the blocking orders.
                  context.showError(failure.message);
                } else {
                  context.showSuccess('أُغلقت الصفقة وعادت الأموال إلى المحافظ');
                }
              },
            ),
            const SizedBox(height: 12),
            Text(
              'الإغلاق يعيد رأس المال إلى محفظة كل مستثمر ويجعل أرباحه قابلة للسحب. '
              'يُرفض ما دامت هناك بضاعة على الرفّ أو طلبية لم تصل العميل بعد.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
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

class _Participant extends StatelessWidget {
  const _Participant({required this.participant, this.standing});

  final DealParticipant participant;
  final DealInvestorStanding? standing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profit = standing?.profit ?? '0.00';
    final isLoss = profit.startsWith('-');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  participant.investor?.name ?? 'مستثمر #${participant.investorId}',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${trimDecimals(participant.sharePercent)}%',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'مموَّل فعلياً: ${(standing?.capital ?? '0.00').grouped} د.ل',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                '${isLoss ? 'خسارة' : 'ربح'}: ${profit.grouped} د.ل',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isLoss ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          // The pledge, shown beside what actually arrived rather than merged with it: a man who
          // agreed to 40,000 and handed over 25,000 should see both numbers, not an average.
          Text(
            'تعهّد بـ ${participant.committedAmount.grouped} د.ل',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
