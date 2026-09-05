import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/changes.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deal_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One deal: its terms, its goods, and what each investor stands at.
class InvestorDealDetailPage extends StatelessWidget {
  const InvestorDealDetailPage({required this.dealId, super.key});

  final int dealId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DealDetailCubit>(
      create: (_) => sl<DealDetailCubit>()..load(dealId),
      child: _DealDetailView(dealId: dealId),
    );
  }
}

class _DealDetailView extends StatefulWidget {
  const _DealDetailView({required this.dealId});

  final int dealId;

  @override
  State<_DealDetailView> createState() => _DealDetailViewState();
}

/// Stateful for one reason: it remembers the deal as it changed, so `pop` can hand the list
/// behind the new row instead of making it re-read the page it is already showing. Opening a
/// deal and closing one both move the status pill, and the row behind used to keep the old one
/// until something else refreshed it.
class _DealDetailViewState extends State<_DealDetailView> {
  final _changes = Changes<InvestorDeal>();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DealDetailCubit>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Always through here, so the back button and the app bar's arrow return the same thing.
        context.pop(_changes.result);
      },
      child: Scaffold(
      floatingActionButtonLocation: AppSpeedDial.location,
      appBar: AppBar(
        title: BlocBuilder<DealDetailCubit, DealDetailState>(
          builder: (context, state) => Text(
            state is DealDetailLoaded ? state.deal.code : 'الصفقة',
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<DealDetailCubit, DealDetailState>(
        builder: (context, state) {
          if (state is! DealDetailLoaded) return const SizedBox.shrink();

          return _Actions(deal: state.deal);
        },
      ),
      body: BlocConsumer<DealDetailCubit, DealDetailState>(
        // Every reading goes past here, whatever produced it — opening the deal, closing it, a
        // pull that picked up somebody else's change.
        listener: (context, state) =>
            _changes.saw(state is DealDetailLoaded ? state.deal : null),
        builder: (context, state) => switch (state) {
          DealDetailLoading() => const Center(child: CircularProgressIndicator()),
          DealDetailFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: () => cubit.load(widget.dealId),
          ),
          DealDetailLoaded(:final deal) => RefreshIndicator(
            onRefresh: () => cubit.load(deal.id),
            child: _Body(deal: deal),
          ),
        },
      ),
      ),
    );
  }
}

/// The one thing a person does to a deal: close it.
///
/// Opening is not an action any more — a deal is born open, with its terms frozen, the moment its
/// purchase order is funded. A closed deal offers nothing, so the dial is absent rather than
/// disabled.
class _Actions extends StatelessWidget {
  const _Actions({required this.deal});

  final InvestorDeal deal;

  Future<void> _close(BuildContext context) async {
    final cubit = context.read<DealDetailCubit>();

    final confirmed = await showCustomDialog(
      context: context,
      title: 'إغلاق الصفقة؟',
      description:
          'يعيد رأس المال إلى محفظة كل مستثمر ويجعل أرباحه قابلة للسحب. '
          'يُرفض ما دامت هناك بضاعة على الرفّ أو طلبية لم تصل العميل بعد.',
      confirmLabel: 'إغلاق وتسوية',
      cancelLabel: 'إلغاء',
      // Not [showDestructiveDialog]: nothing is destroyed — the money goes back where it came
      // from — but a deal cannot be reopened, so it is more than an ordinary yes.
      severity: DialogSeverity.warning,
    );

    if (confirmed != true || !context.mounted) return;

    final failure = await cubit.closeDeal(deal.id);
    if (!context.mounted) return;

    if (failure != null) {
      // The server refuses while stock is left or while an order that took this deal's goods
      // has not reached the customer, and names the blocking orders.
      context.showError(failure.message);

      return;
    }

    context.showSuccess('أُغلقت الصفقة وعادت الأموال إلى المحافظ');
  }

  @override
  Widget build(BuildContext context) {
    return AppSpeedDial(
      actions: [
        if (deal.status == 'open')
          AppAction(
            label: 'إغلاق وتسوية الحسابات',
            icon: AppIcons.settled,
            // The direction that ends something wears the warning colour.
            tone: AppActionTone.warning,
            permission: AppPermission.manageInvestors,
            onTap: _close,
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.deal});

  final InvestorDeal deal;

  @override
  Widget build(BuildContext context) {
    final stock = deal.stock;
    final balances = deal.balances;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
      children: [
        _Terms(deal: deal),
        SizedBox(height: 16.h),

        if (balances != null) ...[
          InvestorMoneyTile(
            label: 'رأس المال في الصفقة',
            amount: balances.capital,
            caption: 'ما يموّل بضاعتها الآن',
            emphasis: true,
          ),
          SizedBox(height: 12.h),
          InvestorMoneyTile(
            label: 'أرباح المستثمرين حتى الآن',
            amount: balances.profit,
            caption: deal.status == 'closed'
                ? 'أُفرج عنها إلى المحافظ'
                : 'تُصرف عند إقفال الصفقة',
          ),
          SizedBox(height: 12.h),
        ],

        // Where that profit came from, one order at a time. Full width, like every action in
        // this app: a button the size of its own label is a target the size of the words in it.
        AppButton.tonal(
          label: 'طلبيات الصفقة',
          icon: AppIcons.orders,
          onPressed: () => context.push(
            Routes.investorDealOrders(deal.id),
            extra: deal.code,
          ),
        ),
        SizedBox(height: 24.h),

        if (stock != null) ...[
          const _SectionTitle(title: 'البضاعة'),
          SizedBox(height: 8.h),
          _Rows(
            rows: [
              ('وصل', groupedDecimal(stock.quantityReceived)),
              ('بِيع', groupedDecimal(stock.quantitySold)),
              ('متبقٍّ', groupedDecimal(stock.quantityRemaining)),
              ('هالك', groupedDecimal(stock.quantityDamaged)),
              ('عجز', groupedDecimal(stock.quantityShort)),
            ],
          ),
          SizedBox(height: 24.h),
        ],

        const _SectionTitle(title: 'المستثمرون'),
        SizedBox(height: 8.h),
        for (final participant in deal.investors)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _Participant(
              participant: participant,
              standing: balances?.perInvestor
                  .where((row) => row.investorId == participant.investorId)
                  .firstOrNull,
            ),
          ),
      ],
    );
  }
}

/// The deal's own terms — the code, where it stands, and the two shares the split runs on.
///
/// The second line appears only when the company put money in beside the partners: it is then
/// a partner for that much, and the investors own only the fraction of the goods their own money
/// bought — «الشركة شريك بـ 17,000 · للمستثمرين 15% من البضاعة». A deal built by hand owns all of
/// its goods and says nothing, exactly as before.
class _Terms extends StatelessWidget {
  const _Terms({required this.deal});

  final InvestorDeal deal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deal.code,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _Pill(label: deal.statusLabel),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '${deal.code} · للمستثمرين '
            '${trimDecimals(deal.investorProfitSharePercent)}% من الربح',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (deal.companyStake != '0.00') ...[
            SizedBox(height: 4.h),
            Text(
              'الشركة شريك بـ ${groupedDecimal(deal.companyStake)} د.ل · للمستثمرين '
              '${trimDecimals(deal.investorFundedPercent)}% من البضاعة',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

/// A short table: a word on one side, a figure on the other.
class _Rows extends StatelessWidget {
  const _Rows({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 8.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: context.textTheme.bodyLarge)),
                  Text(
                    value,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
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
    final scheme = context.colorScheme;
    final profit = standing?.profit ?? '0.00';
    final isLoss = profit.startsWith('-');

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  participant.investor?.name ?? 'مستثمر #${participant.investorId}',
                  style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${trimDecimals(participant.sharePercent)}%',
                textDirection: TextDirection.ltr,
                style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // The two figures are the biggest things on the row — they were drawn smaller than the
          // name above them, which put the least important word at the top of the size order.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Figure(
                  label: 'مموَّل فعلياً',
                  amount: standing?.capital ?? '0.00',
                  colour: scheme.onSurface,
                ),
              ),
              Expanded(
                child: _Figure(
                  label: isLoss ? 'خسارة' : 'ربح',
                  // The label carries the sign — see [unsigned].
                  amount: unsigned(profit),
                  colour: isLoss ? scheme.error : scheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          // The pledge, shown beside what actually arrived rather than merged with it: a man who
          // agreed to 40,000 and handed over 25,000 should see both numbers, not an average.
          // Absent when nobody pledged anything — «تعهّد بـ 0.00» is a promise nobody made.
          if (participant.committedAmount != '0.00' && participant.committedAmount.isNotEmpty)
            Text(
              'تعهّد بـ ${participant.committedAmount.grouped} د.ل',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// A labelled figure: the caption small and quiet, the money big.
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.amount, required this.colour});

  final String label;
  final String amount;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            maxLines: 1,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colour,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

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
              onPressed: onRetry,
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
