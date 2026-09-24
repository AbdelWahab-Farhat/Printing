import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:dayaa/features/investors/models/fund_share.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_profit_tile.dart';
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
    final balances = investor.balances;

    return ListView(
      // `always`, so pull-to-refresh works on an investor short enough not to scroll.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        // لا هاتفَ ولا رمزَ فوق المحفظة — «مش ضروري»؛ الاسمُ في الشريط يكفي. والإيقافُ وحده يبقى،
        // لأنه يغيّر معنى كلِّ رقمٍ تحته.
        if (!investor.isActive) ...[
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: _Pill(label: 'موقوف'),
          ),
          SizedBox(height: 12.h),
        ],

        if (balances != null) ...[
          // **ماله أولاً، في كلّ مكانٍ هو فيه، ثم ما ربحه.** المحفظةُ بطلةُ الشاشة لأنها ما يتحرّك
          // من هنا؛ والصندوقُ تحتها لأن مالَ أكثر المستثمرين فيه، وصفحةٌ تقول «رصيد المحفظة 0»
          // وحدها لرجلٍ مالُه كلُّه في الصندوق تقول إنه لا مال له.
          InvestorMoneyTile.hero(
            label: 'رصيد المحفظة',
            amount: balances.wallet.capital,
            artwork: 'assets/images/wallet.png',
          ),
          SizedBox(height: 12.h),
          if (investor.fund case final fund?) ...[
            _FundTile(fund: fund),
            SizedBox(height: 12.h),
          ],

          // **فتراتُه في مكان الصفقات، ولا صفقةَ بعدها** — قرارُ المالك 2026-09-25: «عرض الفترات
          // بدلا من الصفقات»، والقديمةُ «سوف تغلق وتضاف لربحه ومالناش علاقة بيها».
          if (investor.periods.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'الفترات',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8.h),
            for (final period in investor.periods)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _PeriodRow(period: period),
              ),
            SizedBox(height: 16.h),
          ],

          // **الربحُ كما يقرؤه على بوابته**: مجموعُ البوّابات الثلاث، وزرٌّ لكل واحدة — §٠.٨.
          // ومن لا أرقامَ له منها يرى ما يُسحب وحده، كما كانت الصفحة قبل الصندوق.
          if (investor.profitFigures case final figures?)
            InvestorProfitTile(
              awaitingDelivery: figures.awaitingDelivery,
              pending: figures.pending,
              available: balances.wallet.profit,
            )
          else
            InvestorMoneyTile(label: 'أرباح متاحة للسحب', amount: balances.wallet.profit),
        ],
      ],
    );
  }
}

/// مالُه في الصندوق: ما وضعه، ودفعاتُه بمواعيد فكّها.
///
/// **الرقمُ الكبير رأسُ ماله فيه، لا قيمةُ حصته.** هو ما وضعه ولم يستردّه — سطرُه في لوحة الصندوق،
/// وسقفُ ما يستردّه. والقيمةُ (وحداتُه × سعرَ اليوم) قريبةٌ منه في الحال السويّة، وتقولها بوابتُه.
///
/// **والحبسُ دفعةً دفعة**، لأنه كذلك: من اشترك مرّتين يُفكّ مالُه على مرّتين، و«متى أستردّ مالي؟»
/// سؤالٌ يُسأل على الهاتف.
class _FundTile extends StatelessWidget {
  const _FundTile({required this.fund});

  final FundShare fund;

  @override
  Widget build(BuildContext context) {
    // لا سطرَ تحت الرقم: «نصيبه من ربح P1: …%» رُفض كلامًا لا حاجة له. ولا قرصَ بجانبه:
    // «⊕» هناك كان يُقرأ زرّاً لا يفعل شيئاً.
    //
    // دفعةٌ وحيدة هي كلُّ ما في الصندوق مبلغُها الرقمُ الكبير نفسُه، فتقول موعدَ فكّها وحده.
    final deposits = fund.deposits;
    final onlyOne =
        deposits.length == 1 && thousandths(deposits.single.amount) == thousandths(fund.capital);

    return InvestorMoneyTile(
      label: 'في الصندوق',
      amount: fund.capital,
      footer: deposits.isEmpty
          ? null
          : Column(
              children: [
                for (final deposit in deposits)
                  _DepositLine(deposit: deposit, showsAmount: !onlyOne),
              ],
            ),
    );
  }
}

/// دفعةٌ واحدة: مبلغُها، ومتى يُفكّ حبسُها.
class _DepositLine extends StatelessWidget {
  const _DepositLine({required this.deposit, required this.showsAmount});

  final FundDeposit deposit;

  /// لا، حين يكون المبلغُ هو رقمَ البطاقة نفسَه.
  final bool showsAmount;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final until = DateTime.tryParse(deposit.lockedUntil ?? '');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          if (showsAmount) ...[
            Text(
              '${deposit.amount.grouped} د.ل',
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Text(
              // «متاحة للاسترداد» لا «للسحب»: ما انقضى حبسُه يرجع إلى محفظته بـ«استرداد رأس مال»
              // من لوحة الصندوق، والسحبُ من المحفظة حركةٌ بعده.
              deposit.isLocked
                  ? 'محبوسة إلى ${until == null ? '—' : AppDates.day(until)}'
                  : 'متاحة للاسترداد',
              textAlign: showsAmount ? TextAlign.end : TextAlign.start,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// فترةٌ كان شريكاً فيها، وربحُه فيها.
///
/// تُفتح على شاشتها: «من أين جاء الربح؟» سؤالٌ عن الفترة، وجوابُه طلبياتُها. والمبلغُ أكبرُ ما في
/// الصفّ، ورمزُ الفترة عنوانُه.
class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.period});

  final InvestorPeriod period;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final corner = BorderRadius.circular(16.r);

    return Material(
      color: Colors.transparent,
      borderRadius: corner,
      child: InkWell(
        onTap: () => context.push(Routes.investmentPeriod(period.id), extra: period.code),
        borderRadius: corner,
        child: Container(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
          decoration: _cardDecoration(scheme, radius: corner),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  period.code,
                  style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              Text(
                '${period.profit.grouped} د.ل',
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: period.profit.startsWith('-') ? scheme.error : null,
                ),
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
