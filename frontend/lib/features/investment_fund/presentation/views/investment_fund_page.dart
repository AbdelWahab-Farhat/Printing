import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/arabic_counts.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_fund_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_capital_sheet.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_expense_sheet.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_partner_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// لوحةُ الصندوق — قيمتُه ببنودها، والفترةُ التي تستقبل القيد.
///
/// **المجموعُ فوق وبنودُه تحته، لا المجموعُ وحده.** على هذا الرقم تُقسَّم نسبُ كل مستثمر، فبندٌ
/// مخفيٌّ فيه مالُ أحدهم — ومن يقرأ «٢٦٬٠٠٠» يحتاج أن يعرف كم منها بضاعةٌ ما زالت في المطبعة.
///
/// **والأرباحُ المستحقّة تُعرض مطروحةً بإشارتها** لا مضافةً إلى جانب: هي دَينٌ على الصندوق،
/// وعرضُها بلا إشارةٍ يجعل قارئَها يجمعها.
class InvestmentFundPage extends StatelessWidget {
  const InvestmentFundPage({super.key, this.isEmbedded = false});

  /// مضمَّنةً داخل الصدفة: بلا هيكلٍ ولا شريط، لأن الصدفة تملكهما.
  ///
  /// **السطحُ واحد في الحالتين** — سابقتُه `StockItemsPage.isEmbedded`: نسخةٌ ثانية للتبويب
  /// تعني إصلاحاً يُطبَّق في موضعٍ ويُنسى في الآخر.
  final bool isEmbedded;

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
      child: _FundView(isEmbedded: isEmbedded),
    );
  }
}

class _FundView extends StatelessWidget {
  const _FundView({required this.isEmbedded});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<InvestmentFundCubit, InvestmentFundState>(
        builder: (context, state) => switch (state) {
          InvestmentFundLoading() => const Center(child: CircularProgressIndicator()),
          InvestmentFundFailure(:final failure) => _Retry(message: failure.message),
          InvestmentFundLoaded(:final standing) => RefreshIndicator(
            onRefresh: () => context.read<InvestmentFundCubit>().load(),
            child: _Standing(standing: standing),
          ),
        },
    );

    if (isEmbedded) return body;

    return Scaffold(appBar: AppBar(title: const Text('الصندوق الاستثماري')), body: body);
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

class _Standing extends StatelessWidget {
  const _Standing({required this.standing});

  final FundStanding standing;

  @override
  Widget build(BuildContext context) {
    final value = standing.valuation;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        _Total(amount: value.total),
        SizedBox(height: 20.h),
        _Row(label: 'نقد في الخزينة', amount: value.cash),
        _Row(label: 'بضاعة على الرفّ', amount: value.stockOnShelf),
        _Row(label: 'بضاعة خرجت ولم تُسلَّم', amount: value.goodsInFlight),
        _Row(label: 'سُلِّمت ولم تُحصَّل', amount: value.receivablesAtCost),
        _Row(label: 'أرباح مستحقّة للمستثمرين', amount: value.profitOwed),
        SizedBox(height: 24.h),
        _Unit(price: standing.unitPrice, outstanding: standing.unitsOutstanding),
        SizedBox(height: 24.h),
        if (standing.period case final period?)
          _Period(period: period)
        else
          const _NoPeriod(),
        for (final waiting in standing.waitingPeriods) ...[
          SizedBox(height: 12.h),
          _WaitingPeriod(period: waiting),
        ],
        SizedBox(height: 16.h),
        const _PeriodsButton(),
        if (standing.investors.isNotEmpty) ...[
          SizedBox(height: 28.h),
          _Partners(holders: standing.investors),
        ],
        SizedBox(height: 24.h),
        _Actions(standing: standing),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            'قيمة الصندوق',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          SizedBox(height: 6.h),
          Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// سطرُ بندٍ — بحجم المتن، والرقمُ في آخره فيصير عموداً يُقرأ نزولاً.
///
/// **وكلُّ الأرقام موجبة، بما فيها الأرباح المستحقّة.** كانت تُرسم بسالبٍ أحمر لأنها دَينٌ
/// يُطرح؛ وقرارُ المالك أنها لا تحتاج ذلك — العنوانُ يقول ما هي، والمجموعُ فوقها محسوبٌ في
/// الخادم فلا أحدَ يجمع هذا العمود بيده أصلاً. وإشارةُ الناقص في سطرٍ عربيّ تسبق الرقم من
/// الجهة الخطأ بصرياً، فتُقرأ زينةً لا معنى.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final figure = amount.grouped;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
          SizedBox(width: 8.w),
          Text(
            '$figure د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Period extends StatelessWidget {
  const _Period({required this.period});

  final FundPeriod period;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **البطاقةُ بابٌ لا لافتة.** الأرقامُ التي تحتها — المبيعات، وصافي الربح، ونصيبُ كلٍّ —
    // صحيحةٌ ولا تقول من أين جاءت؛ وصفحةُ الفترة تفتحها على الطلبيات التي صنعتها. وكان الطريقُ
    // الوحيد إليها «سجل الفترات»، فيمرّ من يقرأ الفترةَ الجارية أمامه ولا يعرف أنها تُفتح.
    return InkWell(
      onTap: () => context.push(Routes.investmentPeriod(period.id), extra: period.code),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'الفترة ${period.code} — ${period.statusLabel}',
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // السهمُ هو ما يقول إنها تُفتح — بلا كلمةٍ تحتها تشرح ذلك.
                Icon(AppIcons.forward, size: 20.sp, color: scheme.onSurfaceVariant),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              '${period.startsOn} ← ${period.endsOn}',
              style: context.textTheme.bodyMedium,
            ),
            SizedBox(height: 8.h),
            // **ولمن هذه النافذة؟** المالُ الداخل فيها لا يقاسم شهراً بدأ بالفعل — يُجمَّد
            // نصيبُه إلى الفترة التالية. والسطرُ يقولها قبل أن يضع أحدٌ مالَه ويسأل بعدها.
            Text(
              period.subscriptionServesNextPeriod
                  ? 'اكتتاب الفترة القادمة مفتوح حتى ${period.subscriptionClosesOn}'
                  : 'الاكتتاب مفتوح حتى ${period.subscriptionClosesOn}',
              style: context.textTheme.bodyMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              'حصة المستثمرين ${period.investorProfitSharePercent}%',
              style: context.textTheme.bodyMedium,
            ),
            if (period.overrideReason case final reason?) ...[
              SizedBox(height: 12.h),
              Text('أُقفلت بتجاوز: $reason', style: context.textTheme.bodyMedium),
            ],
            if (period.isDueToClose) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                // **الجدولةُ تُقفلها في ساعتها الأولى**، فبقاءُ هذا السطر يعني أنها صمتت — ويقول
                // منذ متى، لأن «حلّ موعدُها» بلا رقمٍ يُقرأ يوماً وشهراً سواء.
                child: Text(
                  'مستحقّة الإقفال ${sinceDays(period.overdueDays ?? 0)}',
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
                ),
              ),
              SizedBox(height: 12.h),
              const PermissionGate(
                permission: AppPermission.manageInvestors,
                child: _CloseButton(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// فترةٌ «قيد الإغلاق» — انتهت نافذتُها وبقيت لها طلبياتٌ لم تصل أو لم تُحصَّل.
///
/// **لا تحبس أحداً**، لكنها تبقى على اللوحة ما بقيت: «تبقى بلا حدّ، واللوحةُ تصرخ». وهي بابٌ
/// كبطاقة الفترة الجارية، يُفتح على طلبياتها.
class _WaitingPeriod extends StatelessWidget {
  const _WaitingPeriod({required this.period});

  final FundPeriod period;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: () => context.push(Routes.investmentPeriod(period.id), extra: period.code),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'الفترة ${period.code} — ${period.statusLabel}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(AppIcons.forward, size: 20.sp, color: scheme.onSecondaryContainer),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              '${period.startsOn} ← ${period.endsOn}',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer),
            ),
            if (period.owedOrders case final owed? when owed > 0) ...[
              SizedBox(height: 8.h),
              Text(
                'تنتظر ${ordersCount(owed)}',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// زرُّ الإقفال — البابُ الوحيد الذي يصير به الربحُ قابلاً للسحب.
///
/// **ولا يحمل سببَ تجاوزٍ من هنا.** الرفضُ الذي يحتاجه — طلبيةٌ عالقة، أو نافذةٌ لم تنتهِ —
/// يقوله الخادمُ بنصّه، ومن قرّر التجاوز يفعله من حيث يُكتب السبب كاملاً لا من زرٍّ يمرّ.
class _CloseButton extends StatefulWidget {
  const _CloseButton();

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _closing = false;

  Future<void> _close() async {
    setState(() => _closing = true);

    final (period, failure) = await context.read<InvestmentFundCubit>().closePeriod();

    if (!mounted) return;

    setState(() => _closing = false);

    await showCustomSnackBar(
      context: context,
      title: failure?.message ?? _closedAs(period),
      type: failure == null ? SnackType.success : SnackType.error,
    );
  }

  /// ما صارت إليه — **«قيد الإغلاق» ليست «أُقفلت»**: ربحُ ما لم يصل أو لم يُحصَّل لم يُفرَج عنه.
  String _closedAs(FundPeriod? period) {
    if (period != null && period.status == 'closing') {
      final owed = period.owedOrders ?? 0;

      return owed > 0
          ? 'انتهت الفترة ${period.code} — ${period.statusLabel}، تنتظر ${ordersCount(owed)}'
          : 'انتهت الفترة ${period.code} — ${period.statusLabel}';
    }

    return 'أُقفلت — أُفرج عن الأرباح، ورأسُ المال والبضاعة في مكانهما';
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'إقفال الفترة',
      isLoading: _closing,
      onPressed: _closing ? null : _close,
    );
  }
}

class _NoPeriod extends StatefulWidget {
  const _NoPeriod();

  @override
  State<_NoPeriod> createState() => _NoPeriodState();
}

class _NoPeriodState extends State<_NoPeriod> {
  bool _opening = false;

  Future<void> _open() async {
    setState(() => _opening = true);

    final failure = await context.read<InvestmentFundCubit>().open();

    if (!mounted) return;

    setState(() => _opening = false);

    if (failure == null) return;

    await showCustomSnackBar(context: context, title: failure.message, type: SnackType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('لا توجد فترة مفتوحة', style: context.textTheme.bodyMedium),
        SizedBox(height: 16.h),
        PermissionGate(
          permission: AppPermission.manageInvestors,
          child: AppButton(
            label: 'فتح فترة',
            isLoading: _opening,
            onPressed: _opening ? null : _open,
          ),
        ),
      ],
    );
  }
}

/// البابُ إلى الفترات — الحاضرةُ فوقه، وكلُّ ما قبلها خلفه.
///
/// **واللوحةُ تعرض فترةً واحدة عن قصد**: هي التي تستقبل القيد اليوم، وحشرُ السجلِّ كلِّه فوقها
/// يدفن السؤالَ الذي فُتحت الشاشةُ لأجله. وما خلف هذا الزرّ سؤالٌ آخر — **ماذا صنعت كلُّ فترة،
/// وأيُّ طلبيةٍ صنعته، وكم أخذ كلُّ شريكٍ منها**.
class _PeriodsButton extends StatelessWidget {
  const _PeriodsButton();

  @override
  Widget build(BuildContext context) {
    return AppButton.outlined(
      label: 'سجل الفترات',
      onPressed: () => context.push(Routes.investmentPeriods),
    );
  }
}

/// سعرُ الوحدة والوحداتُ القائمة — الرقمان اللذان يجعلان الدخولَ عادلاً.
///
/// **من يقبض مالاً من مستثمرٍ اليوم يحتاج أن يرى السعرَ قبل أن يكتب.** هو ما يقرّر كم وحدةً
/// يشتري ذلك المال، أي كم نسبةً يأخذ من ربح الصندوق — ومن دخل صندوقاً قيمتُه ١٬٦٠٠ ووحداتُه
/// ١٬٠٠٠ يشتري الوحدةَ بـ١٫٦، فلا يقاسم أحداً ربحاً صُنع قبله.
class _Unit extends StatelessWidget {
  const _Unit({required this.price, required this.outstanding});

  final String price;
  final String outstanding;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سعر الوحدة', style: context.textTheme.bodyMedium),
                SizedBox(height: 4.h),
                Text(
                  price,
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوحدات القائمة', style: context.textTheme.bodyMedium),
                SizedBox(height: 4.h),
                Text(
                  outstanding.grouped,
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// الشركاءُ ونسبُهم في هذه الفترة — ومن ينتظر التالية خلف زرٍّ يعدّهم.
///
/// **من اكتتب في نافذة هذه الفترة لا يقف هنا**: لا يقتسم ربحَها، وسطرُه بجانب من يقتسمه كان
/// يوحي بأنه شريكٌ بصفر. يقف في صفحة «شركاء الصندوق» تحت «الفترة القادمة» بنسبته فيها.
class _Partners extends StatelessWidget {
  const _Partners({required this.holders});

  final List<FundHolder> holders;

  @override
  Widget build(BuildContext context) {
    final current = holders.where((h) => !h.shareStartsNextPeriod).toList();
    final joining = holders.length - current.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'الشركاء ونسبُهم في هذه الفترة',
          style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.h),
        for (final holder in current) FundPartnerCard(holder: holder, percent: holder.sharePercent),
        SizedBox(height: 4.h),
        AppButton.outlined(
          label: joining > 0
              ? 'الفترة القادمة — ${arabicCount(joining, one: 'مستثمر واحد ينضمّ', two: 'مستثمران ينضمّان', few: 'مستثمرين ينضمّون', many: 'مستثمراً ينضمّون')}'
              : 'شركاء الفترة الحالية والقادمة',
          onPressed: () => context.push(Routes.investmentPartners),
        ),
      ],
    );
  }
}

/// أزرارُ الصندوق — وكلٌّ منها يظهر متى كان له معنى.
///
/// **زرُّ الإيداع يغيب حين تُغلق نافذةُ الاكتتاب**، والخادمُ هو من قال إنها أُغلقت
/// (`accepts_capital`): مقارنةُ تواريخ هنا نسخةٌ ثانية من القاعدة تخالف الأولى يوم تتغيّر.
class _Actions extends StatelessWidget {
  const _Actions({required this.standing});

  final FundStanding standing;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvestmentFundCubit>();
    final period = standing.period;

    if (period == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (period.acceptsCapital)
          PermissionGate(
            permission: AppPermission.recordInvestorMoney,
            child: AppButton(
              label: 'اشتراك في الصندوق',
              onPressed: () => showFundCapitalSheet(
                context: context,
                cubit: cubit,
                action: FundCapitalAction.deposit,
                standing: standing,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'أُغلقت نافذة الاكتتاب — يُقبل رأس المال في الفترة التالية',
              style: context.textTheme.bodyMedium,
            ),
          ),
        SizedBox(height: 12.h),
        PermissionGate(
          permission: AppPermission.recordInvestorMoney,
          child: AppButton.outlined(
            label: 'استرداد رأس مال',
            onPressed: () => showFundCapitalSheet(
              context: context,
              cubit: cubit,
              action: FundCapitalAction.withdrawal,
              standing: standing,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        PermissionGate(
          permission: AppPermission.recordDealExpenses,
          child: AppButton.outlined(
            label: 'تسجيل مصروف',
            onPressed: () => showFundExpenseSheet(context: context, cubit: cubit),
          ),
        ),
      ],
    );
  }
}
