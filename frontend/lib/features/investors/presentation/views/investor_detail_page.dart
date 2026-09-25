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
          // **«أ · لمحة واحدة»** — الاتجاهُ الذي اختاره المالك 2026-09-25 من ثلاثةٍ رُسمت له:
          // رأسُ ماله كلُّه وأين هو، ثم ربحُه وبوّاباتُه الثلاث، ثم فتراتُه. كلُّ رقمٍ ظاهرٌ بلا
          // لمسة؛ كانت الأرقامُ خلف زرِّ قلبٍ وأربعةِ أزرار.
          _CapitalCard(wallet: balances.wallet.capital, fund: investor.fund),
          SizedBox(height: 12.h),
          _ProfitCard(figures: investor.profitFigures, available: balances.wallet.profit),

          // **فتراتُه في مكان الصفقات، ولا صفقةَ بعدها** — قرارُ المالك 2026-09-25: «عرض الفترات
          // بدلا من الصفقات»، والقديمةُ «سوف تغلق وتضاف لربحه ومالناش علاقة بيها».
          if (investor.periods.isNotEmpty) ...[
            SizedBox(height: 24.h),
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
          ],
        ],
      ],
    );
  }
}

/// **رأسُ ماله كلُّه في البطاقة الكبيرة، وأين هو تحته.** كانت البطاقةُ الكبيرة «رصيد المحفظة»،
/// وهي صفرٌ عند كلِّ من مالُه في الصندوق: أكبرُ ما في الصفحة كان أقلَّها قولاً.
///
/// **والمجموعُ جمعُ الجزأين تحته** ([addDecimals] على السلاسل لا `double`)، فلا يقول الرقمُ الكبير
/// غيرَ ما يُجمع بالإصبع. وهو «رأس المال» نفسُه في سجلّ المستثمرين: الخادمُ لا يعدّ هناك ما بقي
/// في صفقةٍ طُويت في الصندوق، كما لا تعدّه هذه الصفحة.
///
/// **ورقمُ الصندوق رأسُ ماله فيه، لا قيمةُ حصته**: ما وضعه ولم يستردّه — سطرُه في لوحة الصندوق،
/// وسقفُ ما يستردّه. والقيمةُ (وحداتُه × سعرَ اليوم) تقولها بوابتُه.
class _CapitalCard extends StatelessWidget {
  const _CapitalCard({required this.wallet, required this.fund});

  final String wallet;
  final FundShare? fund;

  @override
  Widget build(BuildContext context) {
    if (fund case final fund?) {
      return InvestorMoneyTile.hero(
        label: 'رأس المال',
        amount: addDecimals(wallet, fund.capital),
        artwork: 'assets/images/wallet.png',
        footer: _CapitalSplit(wallet: wallet, fund: fund),
      );
    }

    // خادمٌ لا يرسل `fund`: رأسُ ماله محفظتُه، ولا قسمةَ تُقال.
    return InvestorMoneyTile.hero(
      label: 'رأس المال',
      amount: wallet,
      artwork: 'assets/images/wallet.png',
    );
  }
}

/// المحفظةُ والصندوق جنباً إلى جنب داخل البطاقة الكبيرة، وموعدُ فكّ الصندوق تحت رقمه.
///
/// **والحبسُ دفعةً دفعة**، لأنه كذلك: من اشترك مرّتين يُفكّ مالُه على مرّتين، و«متى أستردّ مالي؟»
/// سؤالٌ يُسأل على الهاتف. دفعةٌ وحيدة هي كلُّ ما في الصندوق تقول موعدَها تحت رقمه بلا مبلغها —
/// مبلغُها رقمُه نفسُه؛ وأكثرُ من واحدة تُسرد تحت القسمة، كلٌّ بمبلغه وموعده.
class _CapitalSplit extends StatelessWidget {
  const _CapitalSplit({required this.wallet, required this.fund});

  final String wallet;
  final FundShare fund;

  @override
  Widget build(BuildContext context) {
    final ink = context.colorScheme.onPrimary;
    final deposits = fund.deposits;
    final onlyOne =
        deposits.length == 1 && thousandths(deposits.single.amount) == thousandths(fund.capital);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            // **زجاجٌ فوق التيل**: أفتحُ منه في الداكن تحت حبرٍ داكن، وأخفُّ في الفاتح تحت حبرٍ
            // أبيض — فيبقى التباينُ مع الحبر في الاثنين.
            color: Colors.white.withValues(alpha: context.isDarkMode ? 0.26 : 0.12),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CapitalPart(label: 'في المحفظة', amount: wallet, ink: ink),
                ),
                VerticalDivider(width: 1, thickness: 1, color: ink.withValues(alpha: 0.2)),
                Expanded(
                  child: _CapitalPart(
                    label: 'في الصندوق',
                    amount: fund.capital,
                    ink: ink,
                    unlocks: onlyOne ? deposits.single : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!onlyOne && deposits.isNotEmpty) ...[
          SizedBox(height: 6.h),
          for (final deposit in deposits) _DepositLine(deposit: deposit, ink: ink),
        ],
      ],
    );
  }
}

/// نصفُ القسمة: اسمُه ومبلغُه، وموعدُ الفكّ تحت الصندوق حين تكون له دفعةٌ واحدة.
class _CapitalPart extends StatelessWidget {
  const _CapitalPart({required this.label, required this.amount, required this.ink, this.unlocks});

  final String label;
  final String amount;
  final Color ink;

  /// الدفعةُ الوحيدة التي هي كلُّ ما في الصندوق.
  final FundDeposit? unlocks;

  @override
  Widget build(BuildContext context) {
    final muted = ink.withValues(alpha: 0.8);
    final quiet = context.textTheme.bodyMedium?.copyWith(
      color: muted,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: quiet),
          SizedBox(height: 2.h),
          // من اليسار داخل شجرةٍ من اليمين، كما في `InvestorMoneyTile`: `43,500` بالاتجاه الآخر
          // رقمٌ آخر. ويصغر ولا يُقصّ حين يطول الرقم على نصف البطاقة.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${amount.grouped} د.ل',
              textDirection: TextDirection.ltr,
              maxLines: 1,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ),
          if (unlocks case final deposit?) ...[
            SizedBox(height: 2.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    deposit.isLocked ? AppIcons.locked : AppIcons.unlocked,
                    size: 14.sp,
                    color: muted,
                  ),
                  SizedBox(width: 5.w),
                  // القفلُ يقول «محبوسة»، فالسطرُ يقول الموعدَ وحده.
                  Text(_unlocking(deposit, lockSaysIt: true), style: quiet),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// دفعةٌ من دفعاته: مبلغُها، ومتى يُفكّ حبسُها — على البطاقة الكبيرة، بحبرها.
class _DepositLine extends StatelessWidget {
  const _DepositLine({required this.deposit, required this.ink});

  final FundDeposit deposit;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      child: Row(
        children: [
          Text(
            '${deposit.amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: ink),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _unlocking(deposit, lockSaysIt: false),
              textAlign: TextAlign.end,
              style: context.textTheme.bodyMedium?.copyWith(color: ink.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }
}

/// متى يُفكّ حبسُ دفعة — «محبوسة إلى 1 سبتمبر 2027»، أو «إلى …» وحدها حين يقف قفلٌ بجانبها.
///
/// «متاحة للاسترداد» لا «للسحب»: ما انقضى حبسُه يرجع إلى محفظته بـ«استرداد رأس مال» من لوحة
/// الصندوق، والسحبُ من المحفظة حركةٌ بعده.
String _unlocking(FundDeposit deposit, {required bool lockSaysIt}) {
  if (!deposit.isLocked) return 'متاحة للاسترداد';

  final until = DateTime.tryParse(deposit.lockedUntil ?? '');
  final day = until == null ? '—' : AppDates.day(until);

  return lockSaysIt ? 'إلى $day' : 'محبوسة إلى $day';
}

/// **ربحُه وبوّاباتُه الثلاث معاً، بلا زرٍّ يُضغط** — §٠.٨ كما يقرؤها على بوابته، لكن مفرودة:
/// كانت أربعةُ أزرارٍ تُظهر رقماً واحداً في كلّ مرّة، و«كم يستطيع أن يسحب؟» سؤالٌ يُسأل على
/// الهاتف. والبوّاباتُ بالترتيب الذي يمرّ به المال فيها، و«متاحة للسحب» آخرُها وأوضحُها.
///
/// ومن لا أرقامَ له منها — خادمٌ لا يرسل `profit_figures` — يرى ما يُسحب وحده، كما كانت الصفحة
/// قبل الصندوق.
class _ProfitCard extends StatelessWidget {
  const _ProfitCard({required this.figures, required this.available});

  final ProfitFigures? figures;

  /// ربحُ محفظته — ما يُسحب اليوم.
  final String available;

  @override
  Widget build(BuildContext context) {
    if (figures case final figures?) {
      return InvestorMoneyTile(
        label: 'الأرباح',
        amount: addDecimals(addDecimals(figures.awaitingDelivery, figures.pending), available),
        footer: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Gate(label: 'قيد التسليم', amount: figures.awaitingDelivery)),
            SizedBox(width: 8.w),
            Expanded(child: _Gate(label: 'معلّقة', amount: figures.pending)),
            SizedBox(width: 8.w),
            Expanded(child: _Gate(label: 'متاحة للسحب', amount: available, emphasis: true)),
          ],
        ),
      );
    }

    return InvestorMoneyTile(label: 'أرباح متاحة للسحب', amount: available);
  }
}

/// بوّابةٌ واحدة: اسمُها ومبلغُها. و«متاحة للسحب» على لون التطبيق — هي ما يُسأل عنه.
class _Gate extends StatelessWidget {
  const _Gate({required this.label, required this.amount, this.emphasis = false});

  final String label;
  final String amount;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ink = emphasis ? scheme.onPrimaryContainer : scheme.onSurface;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: emphasis ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              maxLines: 1,
              style: context.textTheme.bodyMedium?.copyWith(
                color: emphasis ? ink : scheme.onSurfaceVariant,
                fontWeight: emphasis ? FontWeight.w600 : null,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${amount.grouped} د.ل',
              textDirection: TextDirection.ltr,
              maxLines: 1,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                // خسارةٌ مرحَّلة تجعل «معلّقة» سالبة: أحمرُ على البطاقة العادية.
                color: amount.startsWith('-') && !emphasis ? scheme.error : ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// فترةٌ كان شريكاً فيها: رمزُها وحالُها ومدّتُها، وربحُه فيها.
///
/// تُفتح على شاشتها: «من أين جاء الربح؟» سؤالٌ عن الفترة، وجوابُه طلبياتُها. والمبلغُ أكبرُ ما في
/// الصفّ. و«سواء منتهية أو مستمرة» يقولها الوسمُ بجانب الرمز، بلفظ سجلّ الفترات وألوانه.
class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.period});

  final InvestorPeriod period;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final corner = BorderRadius.circular(16.r);
    final starts = DateTime.tryParse(period.startsOn ?? '');
    final ends = DateTime.tryParse(period.endsOn ?? '');

    // الجاريةُ، والمنتظِرةُ طلبياتِها، والمغلقةُ بأرقامها — ألوانُ بطاقات سجلّ الفترات.
    final (fill, ink) = switch (period.status) {
      'open' => (scheme.primaryContainer, scheme.onPrimaryContainer),
      'closing' => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Material(
      color: Colors.transparent,
      borderRadius: corner,
      child: InkWell(
        onTap: () => context.push(Routes.investmentPeriod(period.id), extra: period.code),
        borderRadius: corner,
        child: Container(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 12.w, 12.h),
          decoration: _cardDecoration(scheme, radius: corner),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // `Wrap` لا `Row`: رقمٌ طويل أو خطٌّ مكبَّر في الهاتف يضيّق هذا العمود، فينزل
                    // الوسمُ تحت الرمز بدل أن يفيض خارج البطاقة.
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          period.code,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (period.statusLabel case final label?)
                          _Pill(label: label, fill: fill, ink: ink),
                      ],
                    ),
                    if (starts != null && ends != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        AppDates.span(starts, ends),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${period.profit.grouped} د.ل',
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: period.profit.startsWith('-') ? scheme.error : null,
                ),
              ),
              SizedBox(width: 4.w),
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

/// وسمٌ صغير — «موقوف» بلونه المحايد، وحالُ الفترة بلونها.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.fill, this.ink});

  final String label;
  final Color? fill;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: fill ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(color: ink ?? scheme.onSurfaceVariant),
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
