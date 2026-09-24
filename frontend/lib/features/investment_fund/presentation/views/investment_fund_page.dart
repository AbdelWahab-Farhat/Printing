import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/arabic_counts.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_fund_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_capital_sheet.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_expense_sheet.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_total_card.dart';
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

    return Scaffold(
      // شفّافٌ وبلا شريطٍ حين تملكهما الصدفة — سابقتُه `StockItemsPage`. والهيكلُ في الحالتين،
      // لا المستقلّة وحدها: الزرُّ العائم يحتاج هيكلاً يحمله.
      backgroundColor: isEmbedded ? Colors.transparent : null,
      appBar: isEmbedded ? null : AppBar(title: const Text('الصندوق الاستثماري')),
      floatingActionButtonLocation: AppSpeedDial.location,
      floatingActionButton: BlocBuilder<InvestmentFundCubit, InvestmentFundState>(
        builder: (context, state) => switch (state) {
          InvestmentFundLoaded(:final standing) => _Actions(standing: standing),
          _ => const SizedBox.shrink(),
        },
      ),
      body: body,
    );
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
      // الحاشيةُ السفلى بطولِ الزرّ العائم وأكثر: آخرُ بابٍ في اللوحة لا يُدفن تحته.
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
      children: [
        _Total(amount: value.total),
        SizedBox(height: 20.h),
        // **كلُّ رقمٍ بابٌ إلى ما صنعه** — طلبُ المالك 2026-09-24: النقدُ إلى سجلّه، والبضاعةُ
        // إلى موادّها وطلبياتها، والأرباحُ إلى الطلبيات التي أعطتها. وكلُّ قائمةٍ هناك تجمع إلى
        // الرقم الذي فُتحت منه.
        _Row(label: 'نقد في الخزينة', amount: value.cash, opens: Routes.investmentCash),
        _Row(label: 'بضاعة على الرفّ', amount: value.stockOnShelf, opens: Routes.investmentShelf),
        _Row(
          label: 'بضاعة خرجت ولم تُسلَّم',
          amount: value.goodsInFlight,
          opens: Routes.investmentInFlight,
        ),
        _Row(
          label: 'سُلِّمت ولم تُحصَّل',
          amount: value.receivablesAtCost,
          opens: Routes.investmentReceivables,
        ),
        _Row(
          label: 'أرباح مستحقّة للمستثمرين',
          amount: value.profitOwed,
          opens: Routes.investmentProfitOwed,
        ),
        // **تحت خطٍّ لا بين البنود** — ليس منها: ثمنُ أوامر شراءٍ خرج من الخزينة ولم يصل الرفَّ
        // بعد، وقرارُ المالك أنه لا يدخل القيمة («عرض لأن المال استُعمل بالفعل»). فلو جاور
        // البنودَ لجمعه قارئُها إلى المجموع فوقها.
        Divider(height: 16.h, color: context.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        _Row(
          label: 'بضاعة مشتراة لم تصل',
          amount: standing.goodsOnOrder,
          opens: Routes.investmentOnOrder,
        ),
        SizedBox(height: 24.h),
        _Unit(price: standing.unitPrice, outstanding: standing.unitsOutstanding),
        SizedBox(height: 24.h),
        if (standing.period case final period?) ...[
          _Period(period: period),
          if (!period.acceptsCapital) ...[
            SizedBox(height: 12.h),
            const _SubscriptionClosed(),
          ],
        ] else
          const _NoPeriod(),
        for (final waiting in standing.waitingPeriods) ...[
          SizedBox(height: 12.h),
          _WaitingPeriod(period: waiting),
        ],
        SizedBox(height: 16.h),
        const _Doors(),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    // **سجلُّ الخزينة بجانب قيمة الصندوق** — «ممكن تكون بجانب قيمة الصندوق». البابُ نفسُه الذي
    // يفتحه سطرُ النقد تحته، في الموضع الذي تقع عليه العينُ أوّلاً.
    return FundTotalCard(
      label: 'قيمة الصندوق',
      amount: amount,
      action: IconButton(
        tooltip: 'سجل الخزينة',
        onPressed: () => context.push(Routes.investmentCash),
        icon: Icon(AppIcons.history, color: context.colorScheme.onPrimaryContainer),
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
///
/// **والسطرُ بابٌ**، والسهمُ في آخره هو ما يقول ذلك — كبطاقة الفترة تحته، بلا كلمةٍ تشرحه.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.amount, required this.opens});

  final String label;
  final String amount;

  /// الشاشةُ التي تقول ما يتكوّن منه هذا الرقم.
  final String opens;

  @override
  Widget build(BuildContext context) {
    final figure = amount.grouped;

    return InkWell(
      onTap: () => context.push(opens),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
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
            SizedBox(width: 4.w),
            Icon(AppIcons.forward, size: 18.sp, color: context.colorScheme.onSurfaceVariant),
          ],
        ),
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

/// بابان متجاوران — **سجلُّ الفترات، والمستثمرون**.
///
/// **واللوحةُ تعرض فترةً واحدة عن قصد**: هي التي تستقبل القيد اليوم، وحشرُ السجلِّ كلِّه فوقها
/// يدفن السؤالَ الذي فُتحت الشاشةُ لأجله. وما خلف الباب الأول سؤالٌ آخر — **ماذا صنعت كلُّ
/// فترة، وأيُّ طلبيةٍ صنعته، وكم أخذ كلُّ شريكٍ منها**.
///
/// **والشركاءُ خلف الباب الثاني لا على اللوحة.** قرارُ المالك 2026-09-23: «سجل الفترات يكون
/// بجانبه زر المستثمرين الحاليين، والصفحة فيها تبويبان: الفترة الحالية والفترة القادمة». كانت
/// قائمةُ الشركاء هنا وزرٌّ تحتها إلى القادمة، فصار للسؤال نفسِه نصفان في شاشتين.
class _Doors extends StatelessWidget {
  const _Doors();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton.outlined(
            label: 'سجل الفترات',
            onPressed: () => context.push(Routes.investmentPeriods),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AppButton.outlined(
            label: 'المستثمرون الحاليون',
            onPressed: () => context.push(Routes.investmentPartners),
          ),
        ),
      ],
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

/// أزرارُ الصندوق — **زرٌّ عائمٌ واحد يتفتّح عنها**، كزرّ شاشة العميل.
///
/// قرارُ المالك 2026-09-23: «الأزرار مثل استرداد رأس المال وتسجيل المصروف — كذلك اشتراك في
/// الصندوق — تكون مثل الزرّ العائم الخاص بالعميل». كانت ثلاثةَ أزرارٍ بعرض الشاشة في ذيل
/// اللوحة، لا تُرى إلا بعد تمريرها كلِّها.
///
/// [AppSpeedDial] يفرزها بالصلاحية، ويصير زرّاً واحداً باسمه حين لا يبقى إلا واحد.
///
/// **الاشتراكُ يغيب حين تُغلق نافذةُ الاكتتاب**، والخادمُ هو من قال إنها أُغلقت
/// (`accepts_capital`): مقارنةُ تواريخ هنا نسخةٌ ثانية من القاعدة تخالف الأولى يوم تتغيّر.
/// والسطرُ الذي يقول ذلك في جسم اللوحة — [_SubscriptionClosed] — لا هنا، لأن الزرَّ المطويّ لا
/// يقول شيئاً عمّا غاب منه.
class _Actions extends StatelessWidget {
  const _Actions({required this.standing});

  final FundStanding standing;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvestmentFundCubit>();
    final period = standing.period;

    if (period == null) return const SizedBox.shrink();

    return AppSpeedDial(
      actions: [
        if (period.acceptsCapital)
          AppAction(
            label: 'اشتراك في الصندوق',
            icon: AppIcons.fundDeposit,
            tone: AppActionTone.primary,
            permission: AppPermission.recordInvestorMoney,
            onTap: (context) => showFundCapitalSheet(
              context: context,
              cubit: cubit,
              action: FundCapitalAction.deposit,
              standing: standing,
            ),
          ),
        AppAction(
          label: 'استرداد رأس مال',
          icon: AppIcons.fundWithdraw,
          permission: AppPermission.recordInvestorMoney,
          onTap: (context) => showFundCapitalSheet(
            context: context,
            cubit: cubit,
            action: FundCapitalAction.withdrawal,
            standing: standing,
          ),
        ),
        AppAction(
          label: 'تسجيل مصروف',
          icon: AppIcons.expense,
          permission: AppPermission.recordDealExpenses,
          onTap: (context) => showFundExpenseSheet(context: context, cubit: cubit),
        ),
      ],
    );
  }
}

/// نافذةُ الاكتتاب أُغلقت — يقولها سطرٌ تحت الفترة بدل زرٍّ يغيب بصمت.
class _SubscriptionClosed extends StatelessWidget {
  const _SubscriptionClosed();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
