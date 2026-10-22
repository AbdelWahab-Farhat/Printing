import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/arabic_counts.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/period_orders_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/views/period_expenses_tab.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_figures.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_order_card.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_profit_state_chip.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// تبويبا شاشة الفترة، بترتيبهما.
enum PeriodTab { orders, expenses }

/// شاشةُ الفترة الواحدة — **ما ربحه المستثمرون فيها، طلبيةً طلبية**.
///
/// سجلُّ الفترات يقول «كم ربحت الفترة»، وهذه تقول **من أين جاء ذلك الرقم ومن أخذه**: كلُّ طلبيةٍ
/// أعطت، وتحتها نصيبُ كلِّ شريك منها.
///
/// **والأرقامُ صفوفُ الدفتر نفسُها التي قُبض بها.** الفترةُ المغلقة وُزّع مالُها بأرقامٍ مُعلنة،
/// وإعادةُ اشتقاقها من الـFIFO بعد سنةٍ — بدفترٍ تحرّكت طبقاتُه — كانت تُظهر غيرَ ما دخل الجيوب.
class InvestmentPeriodPage extends StatelessWidget {
  const InvestmentPeriodPage({
    required this.periodId,
    this.periodCode,
    this.opensOn = PeriodTab.orders,
    super.key,
  });

  final int periodId;

  /// يُعرض في الشريط ريثما تصل الفترة، حين فُتحت الشاشة من صفٍّ يعرف رمزَها.
  final String? periodCode;

  /// التبويبُ الذي تُفتح عليه — «المصاريف» حين جاءت من بطاقة مصروفٍ في «مصاريف الصندوق».
  final PeriodTab opensOn;

  @override
  Widget build(BuildContext context) {
    // **تبويبان لا قائمةٌ واحدة.** الطلبياتُ تطول، والمصاريفُ تحتها كانت لا يصلها أحد — وهي
    // نصفُ «من أين جاء الرقم»: ما ربحته الطلبيات، وما أكلته المصاريف منه.
    return BlocProvider(
      create: (_) => PeriodOrdersCubit(getOrders: sl())..load(periodId),
      child: DefaultTabController(
        length: PeriodTab.values.length,
        initialIndex: opensOn.index,
        child: Scaffold(
          appBar: AppBar(
            title: Text(periodCode == null ? 'الفترة' : 'الفترة $periodCode'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'الطلبيات'),
                Tab(text: 'المصاريف'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              BlocBuilder<PeriodOrdersCubit, PeriodOrdersState>(
                builder: (context, state) => switch (state) {
                  PeriodOrdersLoading() => const Center(child: CircularProgressIndicator()),
                  PeriodOrdersFailure(:final failure) => _Retry(
                    message: failure.message,
                    periodId: periodId,
                  ),
                  final PeriodOrdersLoaded loaded => RefreshIndicator(
                    onRefresh: () => context.read<PeriodOrdersCubit>().load(periodId),
                    child: _Body(loaded: loaded),
                  ),
                },
              ),
              PeriodExpensesTab(periodId: periodId),
            ],
          ),
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.periodId});

  final String message;
  final int periodId;

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
              onPressed: () => context.read<PeriodOrdersCubit>().load(periodId),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.loaded});

  final PeriodOrdersLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final held = loaded.held;
    final cubit = context.read<PeriodOrdersCubit>();
    final filters = _filtersFor(held);
    final shown = visiblePeriodOrders(
      held.orders,
      filter: loaded.filter,
      query: loaded.query,
      sort: loaded.sort,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        _Header(period: held.period),
        SizedBox(height: 20.h),
        _Pool(totals: held.totals),
        if (held.orders.isNotEmpty) ...[
          SizedBox(height: 12.h),
          _Headlines(
            period: held.period,
            showOnTheRoad: filters.contains(PeriodOrdersFilter.onTheRoad),
            totals: held.totals.byState,
            selected: loaded.filter,
            onTap: cubit.filterBy,
          ),
        ],
        if (held.investors.isNotEmpty) ...[
          SizedBox(height: 24.h),
          _Ledger(investors: held.investors),
        ],
        SizedBox(height: 28.h),
        Text(
          'الطلبيات',
          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.h),
        if (held.orders.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'لم تُعطِ طلبيةٌ ربحاً للمستثمرين في هذه الفترة بعد',
              style: context.textTheme.bodyMedium,
            ),
          )
        else ...[
          SearchField(hint: 'ابحث برقم الطلبية أو اسم العميل', onChanged: cubit.search),
          SizedBox(height: 10.h),
          _Chips(
            children: [
              FilterOptionChip(
                label: 'الكل',
                count: held.orders.length,
                isSelected: loaded.filter == null,
                onTap: () => cubit.filterBy(null),
              ),
              for (final filter in filters)
                FilterOptionChip(
                  label: filter.label,
                  count: held.totals.byState.ofFilter(filter).orders,
                  isSelected: loaded.filter == filter,
                  onTap: () => cubit.filterBy(filter),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          _Chips(
            children: [
              for (final sort in PeriodOrdersSort.values)
                FilterOptionChip(
                  label: sort.label,
                  isSelected: loaded.sort == sort,
                  onTap: () => cubit.sortBy(sort),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          if (shown.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text('لا طلبيات تطابق البحث', style: context.textTheme.bodyMedium),
            )
          else
            // البابُ إلى الطلبية نفسها، ولا يعود منه شيء: ما تعرضه هذه الشاشة صفوفُ دفترٍ لا
            // تغيّرها شاشةُ الطلبية.
            for (final order in shown)
              PeriodOrderCard(
                key: ValueKey(order.orderId),
                order: order,
                onTap: () => context.push(Routes.order(order.orderId)),
              ),
        ],
      ],
    );
  }

  /// المرشّحاتُ التي تُعرض لهذه الفترة.
  ///
  /// «استُلم» و«في الانتظار» دائماً — هما السؤال، وصفرُ أحدهما جوابٌ («لم يُفرَج عن شيءٍ بعد»).
  /// و«قيد التسليم» ما لم تُغلق الفترة: المغلقةُ لا تُغلق وفيها شيءٌ في الطريق، وما وقع رغم ذلك
  /// يُعرض.
  List<PeriodOrdersFilter> _filtersFor(PeriodOrders held) {
    final onTheRoad =
        held.period.status != 'closed' ||
        held.totals.byState.ofFilter(PeriodOrdersFilter.onTheRoad).orders > 0;

    return [
      PeriodOrdersFilter.received,
      PeriodOrdersFilter.waiting,
      if (onTheRoad) PeriodOrdersFilter.onTheRoad,
    ];
  }
}

/// صفُّ شرائح يُمرَّر أفقياً — أربعُ حالاتٍ بأعدادها لا تسعها شاشةُ هاتف في سطر.
class _Chips extends StatelessWidget {
  const _Chips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, chip) in children.indexed) ...[
            if (index > 0) SizedBox(width: 8.w),
            chip,
          ],
        ],
      ),
    );
  }
}

/// أين ربحُ الفترة من الجيوب — بسؤال المالك نفسِه: **ما استُلم ربحُها، وما ينتظر** (2026-10-21)،
/// بطاقتان كبيرتان بعدد الطلبيات ومجموعها، ولمسُ إحداهما يصفّي القائمة عليها.
///
/// **الأرقامُ من الخادم كما وصلت.** البطاقتان معاً «ربح المستثمرين» فوقهما، وسببُ الانتظار تحت
/// الثانية — في فترةٍ واحدة سببٌ واحد. و«قيد التسليم» تحتهما وحدها: محسوبٌ لا مقيَّد فيقف خارج
/// ذلك المجموع، وما لم يُسعَّر بعد يُعدّ ولا يُخترع له رقم.
class _Headlines extends StatelessWidget {
  const _Headlines({
    required this.period,
    required this.showOnTheRoad,
    required this.totals,
    required this.selected,
    required this.onTap,
  });

  final FundPeriod period;
  final bool showOnTheRoad;
  final PeriodStatesTotals totals;
  final PeriodOrdersFilter? selected;
  final ValueChanged<PeriodOrdersFilter> onTap;

  @override
  Widget build(BuildContext context) {
    final gap = 10.w;

    _HeadlineCard card(PeriodOrdersFilter filter, List<String> notes, PeriodProfitState tone) =>
        _HeadlineCard(
          filter: filter,
          total: totals.ofFilter(filter),
          notes: notes,
          tone: tone,
          isSelected: selected == filter,
          onTap: () => onTap(filter),
        );

    final heldForPayment = totals.awaitingPayment.orders > 0;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: card(PeriodOrdersFilter.received, [
                  if (period.status == 'open' && totals.released.orders == 0)
                    'يُفرج عنه بعد انتهاء الفترة',
                ], PeriodProfitState.released),
              ),
              SizedBox(width: gap),
              Expanded(
                child: card(
                  PeriodOrdersFilter.waiting,
                  [
                    if (totals.awaitingPeriodEnd.orders > 0) 'حتى تنتهي الفترة',
                    if (heldForPayment) 'حتى يُحصَّل ثمنها',
                  ],
                  heldForPayment
                      ? PeriodProfitState.awaitingPayment
                      : PeriodProfitState.awaitingPeriodEnd,
                ),
              ),
            ],
          ),
        ),
        if (showOnTheRoad) ...[
          SizedBox(height: gap),
          card(PeriodOrdersFilter.onTheRoad, [
            if (totals.awaitingDelivery.unpriced > 0)
              'منها ${ordersCount(totals.awaitingDelivery.unpriced)} لم تُسعَّر',
            'متوقَّع عند التسليم — ليس في المجموع أعلاه',
          ], PeriodProfitState.awaitingDelivery),
        ],
      ],
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({
    required this.filter,
    required this.total,
    required this.notes,
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  final PeriodOrdersFilter filter;
  final PeriodStateTotal total;

  /// سطورٌ صغيرة تحت العدد: سببُ الانتظار، أو ما لم يُسعَّر.
  final List<String> notes;

  /// لونُ البطاقة — لونُ شريحة الحالة التي تمثّلها على بطاقات الطلبيات.
  final PeriodProfitState tone;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (background, foreground) = periodProfitStateColors(context, tone);
    final radius = BorderRadius.circular(16.r);

    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: isSelected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filter.label,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${total.amount.grouped} د.ل',
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: total.amount.startsWith('-') ? scheme.error : foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                total.orders == 0 ? 'لا طلبيات' : ordersCount(total.orders),
                style: context.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              for (final note in notes)
                Text(
                  note,
                  style: context.textTheme.bodySmall?.copyWith(color: foreground),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ترويسةُ الفترة: نافذتُها وحالتُها، وأرقامُها المجمّدة إن أُقفلت.
class _Header extends StatelessWidget {
  const _Header({required this.period});

  final FundPeriod period;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الفترة ${period.code}',
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              PeriodStatusChip(status: period.status, label: period.statusLabel),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            '${period.startsOn} ← ${period.endsOn}',
            style: context.textTheme.bodyMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            'حصة المستثمرين ${period.investorProfitSharePercent}%',
            style: context.textTheme.bodyMedium,
          ),
          if (period.owedOrders case final owed? when owed > 0) ...[
            SizedBox(height: 8.h),
            Text('تنتظر ${ordersCount(owed)}', style: context.textTheme.bodyMedium),
          ],
          if (period.overrideReason case final reason?) ...[
            SizedBox(height: 8.h),
            Text('أُقفلت بتجاوز: $reason', style: context.textTheme.bodyMedium),
          ],
          if (period.netProfit != null) ...[
            SizedBox(height: 12.h),
            PeriodFigures(period: period),
          ],
        ],
      ),
    );
  }
}

/// ما أخذه المستثمرون من طلبيات هذه الفترة — مجموعُ صفوفها هي لا رقمٌ ثانٍ.
///
/// **ويفترق عن «للمستثمرين» في أرقام الإقفال عن قصد**: ذاك ما أُفرِج عنه يوم أُقفلت، وهذا ما
/// قُيِّد طلبيةً طلبية. يتساويان في الحال السويّة، ويفترقان حين تحمل الفترةُ خسارةً شُطبت من
/// رأس المال.
class _Pool extends StatelessWidget {
  const _Pool({required this.totals});

  final PeriodOrdersTotals totals;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isNegative = totals.investorsTotal.startsWith('-');

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
            'ربح المستثمرين من طلبيات الفترة',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          SizedBox(height: 6.h),
          Text(
            '${totals.investorsTotal.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.headlineSmall?.copyWith(
              color: isNegative ? scheme.error : scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'من ${totals.orders} طلبية',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

/// سجلُّ ربح المستثمرين في الفترة — كلُّ شريكٍ ومجموعُ ما أخذه من طلبياتها.
class _Ledger extends StatelessWidget {
  const _Ledger({required this.investors});

  final List<PeriodInvestorShare> investors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'سجل ربح المستثمرين',
          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.h),
        for (final share in investors) _LedgerRow(share: share),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.share});

  final PeriodInvestorShare share;

  /// سؤالُ المستثمر نفسُه: «كم وصلني من هذه الفترة، وكم بقي» — ما ليس صفراً وحده.
  String? get _split {
    final parts = [
      if (!_isZero(share.released)) 'استُلم ${share.released.grouped}',
      if (!_isZero(share.pending)) 'ينتظر ${share.pending.grouped}',
      if (!_isZero(share.expected)) 'في الطريق ${share.expected.grouped}',
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }

  static bool _isZero(String amount) => (double.tryParse(amount) ?? 0) == 0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isNegative = share.amount.startsWith('-');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(share.name, style: context.textTheme.bodyMedium),
                if (_split != null)
                  Text(
                    _split!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '${share.amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isNegative ? scheme.error : scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
