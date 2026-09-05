import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/investors/presentation/widgets/wallet_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One investor: what his money is doing, and the moves that put it there.
class InvestorDetailPage extends StatelessWidget {
  const InvestorDetailPage({required this.investorId, super.key});

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
    final cubit = context.read<InvestorDetailCubit>();

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<InvestorDetailCubit, InvestorDetailState>(
          // The name once it is known, so the bar stops saying something generic the moment it
          // can say something useful.
          builder: (context, state) => Text(
            state is InvestorDetailLoaded ? state.investor.name : 'المستثمر',
          ),
        ),
      ),
      // **The action is a bar across the bottom, not a floating button.** There is one thing to
      // do on this screen and it is done with a thumb; a button the width of the phone is the
      // target that takes, and it stops the last deal in the list from hiding under a pill.
      bottomNavigationBar: BlocBuilder<InvestorDetailCubit, InvestorDetailState>(
        builder: (context, state) {
          if (state is! InvestorDetailLoaded) return const SizedBox.shrink();

          return _RecordBar(investor: state.investor);
        },
      ),
      body: BlocBuilder<InvestorDetailCubit, InvestorDetailState>(
        builder: (context, state) => switch (state) {
          InvestorDetailLoading() => const Center(child: CircularProgressIndicator()),
          InvestorDetailFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: () => cubit.load(investorId),
          ),
          InvestorDetailLoaded(:final investor) => RefreshIndicator(
            onRefresh: () => cubit.load(investor.id),
            child: _Body(investor: investor),
          ),
        },
      ),
    );
  }
}

/// The one thing this screen does, across the bottom of it.
///
/// Behind a [PermissionGate] rather than a `can(...)` written here, and absent rather than
/// disabled: a reader who may look at an investor and not move his money sees the screen end
/// where its list ends.
class _RecordBar extends StatelessWidget {
  const _RecordBar({required this.investor});

  final Investor investor;

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permission: AppPermission.recordInvestorMoney,
      child: Container(
        color: context.colorScheme.surface,
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: AppButton(
            label: 'تسجيل حركة مالية',
            icon: AppIcons.payment,
            // The sheet reads his deals itself. Built from `balances.deals` it listed only the
            // ones he had already put money into, which made the *first* funding of any deal
            // impossible to record.
            onPressed: () => showWalletEntrySheet(
              context: context,
              cubit: context.read<InvestorDetailCubit>(),
              investor: investor,
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.investor});

  final Investor investor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final balances = investor.balances;

    return ListView(
      // `always`, so pull-to-refresh works on an investor short enough not to scroll.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        _Identity(investor: investor),
        SizedBox(height: 16.h),

        if (balances != null) ...[
          // **Two figures rather than one total.** What is free and what is committed are
          // different answers to «كم ماله عندنا؟», and a single number would answer neither.
          // The wallet is the hero of the screen; the profit sits under it as a plain card,
          // which is the difference between «ماله» and «ما ربحه» said without a word.
          InvestorMoneyTile.hero(
            label: 'رصيد المحفظة',
            amount: balances.wallet.capital,
            caption: 'متاح للتمويل أو للسحب',
            artwork: 'assets/images/wallet.png',
          ),
          SizedBox(height: 12.h),
          InvestorMoneyTile(
            label: 'أرباح متاحة للسحب',
            amount: balances.wallet.profit,
            caption: 'أُفرجت عنها بإقفال صفقة',
            icon: AppIcons.report,
          ),
          SizedBox(height: 24.h),

          const _SectionTitle(title: 'في الصفقات'),
          SizedBox(height: 8.h),
          if (balances.deals.isEmpty)
            Text(
              'لا مال له في أي صفقة',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            for (final pots in balances.deals)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _DealRow(pots: pots),
              ),
        ],
      ],
    );
  }
}

/// A heading with the glyph of what is under it, so a screen of cards is found by shape.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Container(
          height: 36.w,
          width: 36.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primaryContainer),
          child: Icon(AppIcons.investorDeals, size: 18.sp, color: scheme.onPrimaryContainer),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// Who he is, in the one line that gets read out on the phone.
class _Identity extends StatelessWidget {
  const _Identity({required this.investor});

  final Investor investor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: _cardDecoration(scheme),
      child: Row(
        children: [
          Container(
            height: 48.w,
            width: 48.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.secondaryContainer),
            child: Icon(AppIcons.person, size: 24.sp, color: scheme.onSecondaryContainer),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  investor.name,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        [if (investor.phone != null) investor.phone!, investor.code].join(' · '),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(AppIcons.phone, size: 16.sp, color: scheme.primary),
                  ],
                ),
              ],
            ),
          ),
          if (!investor.isActive) const _Pill(label: 'موقوف'),
        ],
      ),
    );
  }
}

/// What he has in one deal, and what it has made him so far.
///
/// It opens the deal. The chevron is the promise, and the money on the row is the reason
/// somebody follows it — «من أين جاء الربح؟» is a question about the deal, not about him.
class _DealRow extends StatelessWidget {
  const _DealRow({required this.pots});

  final DealPots pots;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isLoss = pots.profit.startsWith('-');
    final corner = BorderRadius.circular(16.r);

    return Material(
      color: Colors.transparent,
      borderRadius: corner,
      child: InkWell(
        onTap: () => context.push(Routes.investorDeal(pots.investorDealId)),
        borderRadius: corner,
        child: Container(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
          decoration: _cardDecoration(scheme, radius: corner),
          child: Row(
            children: [
              Container(
                height: 40.w,
                width: 40.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHigh,
                ),
                child: Icon(
                  AppIcons.investorDeals,
                  size: 18.sp,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'صفقة #${pots.investorDealId}',
                  style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The money is the biggest thing on the row and the deal's number is the
                  // caption — a row where nothing is bigger than anything else is a row with no
                  // answer on it.
                  Text(
                    '${pots.capital.grouped} د.ل',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    // `unsigned`: the word already says which direction this is, and «خسارة
                    // -1,500» says it twice — which reads as a negative loss.
                    '${isLoss ? 'خسارة' : 'ربح'} ${unsigned(pots.profit).grouped} د.ل',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isLoss ? scheme.error : scheme.primary,
                    ),
                  ),
                ],
              ),
              Icon(AppIcons.forward, size: 20.sp, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// The card every white box on this screen is drawn in — the app's own, from [RegisterCard]:
/// the shadow is painted under the fill rather than behind the whole rounded rectangle, which is
/// what keeps it outside the edge instead of washing across the card's face.
BoxDecoration _cardDecoration(ColorScheme scheme, {BorderRadius? radius}) => BoxDecoration(
  color: scheme.surfaceContainerLowest,
  borderRadius: radius ?? BorderRadius.circular(20.r),
  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
  boxShadow: [
    BoxShadow(
      color: scheme.shadow.withValues(alpha: 0.05),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ],
);

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
