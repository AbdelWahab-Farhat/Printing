import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/arabic_counts.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:dayaa/features/investor_portal/presentation/viewmodel/investor_portal_cubit.dart';
import 'package:dayaa/features/investor_portal/presentation/widgets/investor_deal_card.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/notifications/presentation/widgets/notification_bell.dart';
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
          // **Not a copy of the shell's bell — the same widget.** This page is top level, beside
          // the splash and the login screen rather than inside the shell, so the staff bar's
          // bell is invisible to an investor. Writing the badge inline in RootPage would have
          // left every investor without one.
          const NotificationBell(),
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

        // **نصيبُه من الصندوق قبل كل شيء**، لأنه اليوم الطريقُ الذي دخل منه: صفقاتُه — إن كانت
        // له صفقات — تاريخٌ يجري إلى نهايته، والوحداتُ هي ما يعمل.
        if (portfolio.fund case final fund?) ...[
          _FundShareCard(fund: fund),
          SizedBox(height: 24.h),
        ],

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

        // **ثلاثُ بوّاباتٍ متتابعة — §٠.٨ من مواصفة الصندوق —** ثم ما قبضه فعلاً. الأوّلُ محسوبٌ
        // لا مقيَّد: طلبياتٌ بلغت «جاهزة» ولم تُسلَّم. والثاني سُلِّم فقُيِّد، ولا يُسحب حتى تنقضي
        // فترتُه ويُحصَّل. والثالثُ اجتمع شرطاه. رقمٌ واحد لها كان سيَعِد بمالٍ لا يُسحب.
        InvestorMoneyTile(
          label: 'ربح قيد التسليم',
          amount: portfolio.profitAwaitingDelivery,
          caption: portfolio.ordersAwaitingDelivery > 0
              ? 'من ${ordersCount(portfolio.ordersAwaitingDelivery)} في الطريق'
              : 'لا طلبيات في الطريق',
        ),
        SizedBox(height: 12.h),
        InvestorMoneyTile(
          label: 'أرباح معلّقة',
          amount: portfolio.profitInDeals,
          caption: 'سُلِّمت — تُتاح بانتهاء فترتها وتحصيلها',
          emphasis: true,
        ),
        SizedBox(height: 12.h),
        InvestorMoneyTile(
          label: 'أرباح متاحة للسحب',
          amount: portfolio.profitAvailable,
          caption: 'انتهت فترتها وحُصِّلت',
        ),
        SizedBox(height: 12.h),
        InvestorMoneyTile(
          label: 'أرباح مسحوبة',
          amount: portfolio.profitWithdrawn,
          caption: 'ما استلمتَه فعلاً',
        ),
        SizedBox(height: 24.h),

        // قائمةُ الصفقات تبقى لمن له صفقاتٌ قديمة، وتغيب عمّن دخل الصندوق مباشرةً: عنوانٌ
        // فوق فراغٍ يجعله يظنّ أن شيئاً لم يُسجَّل.
        if (portfolio.deals.isNotEmpty) ...[
          Text(
            'صفقاتي',
            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8.h),
          for (final deal in portfolio.deals)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: InvestorDealCard(deal: deal),
            ),
        ],
      ],
    );
  }
}

/// نصيبُه من الصندوق: ما تساويه حصتُه، ونسبتُه، ومتى يخرج مالُه.
///
/// **«قيمة حصتي» فوق، والنسبةُ تحتها.** الرجلُ يسأل «كم مالي؟» قبل «كم نسبتي؟»؛ والنسبةُ جوابُ
/// سؤالٍ آخر — كم آخذ من ربح هذا الشهر.
///
/// **ومواعيدُ الحبس دفعةً دفعة**، لأن الحبسَ كذلك: من أودع مرّتين يخرج مالُه على مرّتين.
class _FundShareCard extends StatelessWidget {
  const _FundShareCard({required this.fund});

  final FundShare fund;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حصتي في الصندوق',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          SizedBox(height: 6.h),
          Text(
            '${fund.value.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '${fund.units.grouped} وحدة، سعر الوحدة ${fund.unitPrice}',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          if (fund.period case final period?) ...[
            SizedBox(height: 10.h),
            Text(
              fund.shareStartsNextPeriod
                  ? 'نصيبي يبدأ من الفترة القادمة'
                  : 'نصيبي من ربح ${period.code}: ${_twoPlaces(fund.sharePercent)}%',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${period.startsOn} ← ${period.endsOn}',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ],
          if (fund.deposits.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Text(
              'دفعاتي ومواعيد فكّها',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            for (final deposit in fund.deposits)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Text(
                  deposit.isLocked
                      ? '${deposit.amount.grouped} د.ل — محبوسة إلى ${deposit.lockedUntil ?? '—'}'
                      : '${deposit.amount.grouped} د.ل — متاحة للسحب',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _twoPlaces(String value) {
    final parsed = double.tryParse(value);

    return parsed == null ? value : parsed.toStringAsFixed(2);
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
