import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/arabic_counts.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/text_direction.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/period_orders_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/views/period_expenses_tab.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_figures.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_order_row.dart';
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
///
/// **تصميم ب (2026-10-25)**: «طريقة عرض سيئة» — الرقمُ نفسُه أربعَ مرّات، وأربعةُ ألوانِ بطاقات،
/// وجملٌ تحت الأرقام. صار: سطرُ النافذة، فالمجموع، فثلاثُ بلاطاتٍ متساوية هي المرشّح، فقائمةٌ
/// واحدة.
///
/// **والمجموعُ صافٍ بعد المصاريف (2026-10-28)**: «وضّح للمستثمرين كم سيصبح ربحهم … لإن هذا
/// مربك». بطاقةُ الصافي مكانَه، والمستثمرون جدولاً: الربح، والمصاريف، والصافي.
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
            // رمزُ الفترة كما وصلت: الشريطُ وحده يحمله منذ ذهبت الترويسةُ التي كانت تكرّره.
            title: BlocBuilder<PeriodOrdersCubit, PeriodOrdersState>(
              builder: (context, state) {
                final code = state is PeriodOrdersLoaded ? state.held.period.code : periodCode;

                return Text(code == null ? 'الفترة' : 'الفترة $code');
              },
            ),
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
              // ومعه مجاميعُ الطلبيات متى وصلت، ليقول «المصاريف» صافيَ الربح بعدها بلا نداءٍ ثانٍ.
              BlocBuilder<PeriodOrdersCubit, PeriodOrdersState>(
                builder: (context, state) => PeriodExpensesTab(
                  periodId: periodId,
                  ordersTotals: state is PeriodOrdersLoaded ? state.held.totals : null,
                  onReversed: () => unawaited(context.read<PeriodOrdersCubit>().load(periodId)),
                ),
              ),
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
        SizedBox(height: 16.h),
        _NetCard(totals: held.totals),
        if (held.orders.isNotEmpty) ...[
          SizedBox(height: 16.h),
          // البلاطاتُ تجمع إلى ربح الطلبيات لا إلى الصافي فوقها — فيُقال ذلك مرّةً فوقها.
          Text(
            'ربح الطلبيات حسب حالتها',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          _Tiles(
            filters: _filtersFor(held),
            totals: held.totals.byState,
            selected: loaded.filter,
            onTap: cubit.filterBy,
          ),
        ],
        if (_InvestorsTable.rowsOf(held.investors).isNotEmpty) ...[
          SizedBox(height: 16.h),
          _ListCard(
            title: 'المستثمرون',
            rows: [_InvestorsTable(investors: held.investors, totals: held.totals)],
          ),
        ],
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'الطلبيات',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (held.orders.isNotEmpty) _SortButton(selected: loaded.sort, onSelected: cubit.sortBy),
          ],
        ),
        SizedBox(height: 8.h),
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
          SizedBox(height: 12.h),
          if (shown.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text('لا طلبيات تطابق البحث', style: context.textTheme.bodyMedium),
            )
          else
            _ListCard(
              rows: [
                // البابُ إلى الطلبية نفسها، ولا يعود منه شيء: ما تعرضه هذه الشاشة صفوفُ دفترٍ لا
                // تغيّرها شاشةُ الطلبية.
                for (final order in shown)
                  PeriodOrderRow(
                    key: ValueKey(order.orderId),
                    order: order,
                    onTap: () => context.push(Routes.order(order.orderId)),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  /// البلاطاتُ التي تُعرض لهذه الفترة.
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

/// نافذةُ الفترة وحصّةُ المستثمرين سطراً بجانب شريحة حالتها، وأرقامُها المجمّدة إن أُقفلت.
///
/// **لا بطاقةَ ولا رمزَ فترة**: الرمزُ في الشريط فوقها، وبطاقةٌ له كانت تكرّره.
class _Header extends StatelessWidget {
  const _Header({required this.period});

  final FundPeriod period;

  String get _window {
    final starts = DateTime.tryParse(period.startsOn);
    final ends = DateTime.tryParse(period.endsOn);
    // معزولةً: «50%» في سطرٍ عربيّ كانت تُرسم «%50».
    final share = '${period.investorProfitSharePercent.grouped}%'.isolated;

    return [
      if (starts != null && ends != null) AppDates.span(starts, ends),
      'حصة المستثمرين $share',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final muted = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(_window, style: muted)),
            SizedBox(width: 8.w),
            PeriodStatusChip(status: period.status, label: period.statusLabel),
          ],
        ),
        if (period.owedOrders case final owed? when owed > 0) ...[
          SizedBox(height: 4.h),
          Text('تنتظر ${ordersCount(owed)}', style: muted),
        ],
        if (period.overrideReason case final reason?) ...[
          SizedBox(height: 4.h),
          Text('أُقفلت بتجاوز: $reason', style: muted),
        ],
        if (period.netProfit != null) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: PeriodFigures(period: period),
          ),
        ],
      ],
    );
  }
}

/// صافي ربح المستثمرين بعد مصاريف الفترة — «كم سيصبح ربحهم» (تصميم ب، 2026-10-28).
///
/// المصروفُ نقص من محافظهم يومَ سُجِّل، فربحُ الطلبيات وحده كان يُقرأ أكبرَ مما لهم. **الأرقامُ
/// الثلاثة من الخادم** ولا يُطرح هنا شيء؛ الشريطُ وحده حسابُ عرض: كم بقي من ربح الطلبيات. ولمسُ
/// البطاقة يفتح «المصاريف».
///
/// **ويفترق ربحُ الطلبيات عن «للمستثمرين» في أرقام الإقفال عن قصد**: ذاك ما أُفرِج عنه يوم
/// أُقفلت، وهذا ما قُيِّد طلبيةً طلبية. يتساويان في الحال السويّة، ويفترقان حين تحمل الفترةُ
/// خسارةً شُطبت من رأس المال.
class _NetCard extends StatelessWidget {
  const _NetCard({required this.totals});

  final PeriodOrdersTotals totals;

  /// ما بقي من ربح الطلبيات بعد المصاريف، بين صفرٍ وواحد — و`null` حيث لا شيءَ يُقسم: لا ربح،
  /// أو لا مصروف، أو ردٌّ زاد عليه.
  double? get _kept {
    final profit = double.tryParse(totals.investorsTotal) ?? 0;
    final expenses = double.tryParse(totals.expensesOnInvestors) ?? 0;

    if (profit <= 0 || expenses <= 0) return null;

    return ((profit - expenses) / profit).clamp(0.0, 1.0);
  }

  String get _source {
    final profit = totals.investorsTotal.grouped.isolated;
    final expenses = totals.expensesOnInvestors;

    if (_isZero(expenses)) return 'ربح الطلبيات $profit — لا مصاريف عليهم بعد';

    return expenses.startsWith('-')
        ? 'من ربح الطلبيات $profit ومعه ردُّ مصاريف ${expenses.substring(1).grouped.isolated}'
        : 'من ربح الطلبيات $profit بعد مصاريف ${expenses.grouped.isolated}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ink = scheme.onPrimaryContainer;
    final kept = _kept;
    final radius = BorderRadius.circular(20.r);

    return Material(
      color: scheme.primaryContainer,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => DefaultTabController.of(context).animateTo(PeriodTab.expenses.index),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'صافي ربح المستثمرين',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${totals.net.grouped} د.ل',
                textDirection: TextDirection.ltr,
                style: context.textTheme.headlineMedium?.copyWith(
                  color: totals.net.startsWith('-') ? scheme.error : ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (kept != null) ...[
                SizedBox(height: 10.h),
                // الباقي من جهة البداية، وما أكلته المصاريف بعده.
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: SizedBox(
                    height: 8.h,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: scheme.error),
                        FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: kept,
                          child: ColoredBox(color: ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _source,
                      style: context.textTheme.bodyMedium?.copyWith(color: ink),
                    ),
                  ),
                  Icon(AppIcons.forward, size: 18.sp, color: ink),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// أين ربحُ الفترة من الجيوب — بسؤال المالك نفسِه: **ما استُلم ربحُها، وما ينتظر** (2026-10-21)،
/// وما في الطريق. ثلاثُ بلاطاتٍ متساوية في صفٍّ واحد، **ولمسُ إحداها يصفّي القائمة** ولمسُها
/// ثانيةً يُطفئه — فلا صفَّ شرائح يكرّر أسماءها.
///
/// **الأرقامُ من الخادم كما وصلت.** ولا جملةَ تحت أيٍّ منها: سببُ الانتظار لونُ نقطتها، و«قيد
/// التسليم» مخطّطةٌ بلا لون لأنها توقّعٌ خارج المجموع فوقها.
class _Tiles extends StatelessWidget {
  const _Tiles({
    required this.filters,
    required this.totals,
    required this.selected,
    required this.onTap,
  });

  final List<PeriodOrdersFilter> filters;
  final PeriodStatesTotals totals;
  final PeriodOrdersFilter? selected;
  final ValueChanged<PeriodOrdersFilter> onTap;

  /// في فترةٍ واحدة سببُ انتظارٍ واحد: «قيد الإغلاق» تنتظر التحصيل، والمفتوحةُ موعدَها.
  PeriodProfitState _toneOf(PeriodOrdersFilter filter) => switch (filter) {
    PeriodOrdersFilter.received => PeriodProfitState.released,
    PeriodOrdersFilter.waiting =>
      totals.awaitingPayment.orders > 0
          ? PeriodProfitState.awaitingPayment
          : PeriodProfitState.awaitingPeriodEnd,
    PeriodOrdersFilter.onTheRoad => PeriodProfitState.awaitingDelivery,
  };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, filter) in filters.indexed) ...[
            if (index > 0) SizedBox(width: 8.w),
            Expanded(
              child: _Tile(
                filter: filter,
                total: totals.ofFilter(filter),
                tone: _toneOf(filter),
                unpriced: filter == PeriodOrdersFilter.onTheRoad
                    ? totals.awaitingDelivery.unpriced
                    : 0,
                isSelected: selected == filter,
                onTap: () => onTap(filter),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.filter,
    required this.total,
    required this.tone,
    required this.unpriced,
    required this.isSelected,
    required this.onTap,
  });

  final PeriodOrdersFilter filter;
  final PeriodStateTotal total;
  final PeriodProfitState tone;

  /// ما في الطريق ولم يُسعَّر بعد — يُعدّ ولا يُخترع له رقم.
  final int unpriced;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final outside = filter == PeriodOrdersFilter.onTheRoad;
    final ink = total.orders == 0 ? scheme.onSurfaceVariant : scheme.onSurface;
    final muted = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final radius = BorderRadius.circular(16.r);

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: outside ? Colors.transparent : scheme.surfaceContainer,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : outside
                    ? scheme.outlineVariant
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PeriodProfitStateDot(state: tone, size: 8.r),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        filter.label,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    total.amount.grouped,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: total.amount.startsWith('-') ? scheme.error : ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(total.orders == 0 ? 'لا طلبيات' : ordersCount(total.orders), style: muted),
                if (unpriced > 0)
                  Text(
                    'منها ${ordersCount(unpriced)} لم تُسعَّر',
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقةُ صفوفٍ بفواصل — «المستثمرون» وقائمةُ الطلبيات، بشكل بطاقات «أرباح معلّقة».
class _ListCard extends StatelessWidget {
  const _ListCard({required this.rows, this.title});

  final String? title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final hairline = scheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: hairline),
      ),
      // شفّافةٌ فوق لون البطاقة: بلاها يُرسم أثرُ اللمس تحت اللون فلا يُرى.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title case final title?) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Divider(height: 1, color: hairline),
            ],
            for (final (index, row) in rows.indexed) ...[
              if (index > 0) Divider(height: 1, indent: 16.w, endIndent: 16.w, color: hairline),
              row,
            ],
          ],
        ),
      ),
    );
  }
}

bool _isZero(String amount) => (double.tryParse(amount) ?? 0) == 0;

/// المستثمرون جدولاً: ربحُ كلٍّ من الطلبيات، وما تحمّله من المصاريف، وصافيه — وسطرُ المجموع
/// تحتها هو البطاقةُ فوق (تصميم ب، 2026-10-28). **الأرقامُ من الخادم كما وصلت**، والصافي لا
/// يُطرح هنا.
///
/// بلا «د.ل» في الخانات: أربعةُ أعمدةٍ على هاتفٍ لا تتّسع لها، والبطاقةُ فوقها تقولها. و«في
/// الطريق» ليس عموداً: خارجُ الدفتر، وبلاطتُه فوق.
class _InvestorsTable extends StatelessWidget {
  const _InvestorsTable({required this.investors, required this.totals});

  final List<PeriodInvestorShare> investors;
  final PeriodOrdersTotals totals;

  /// من له في الدفتر شيء — ربحٌ أو مصروف. ومن لا شيءَ له إلا في الطريق لا سطرَ له هنا.
  static List<PeriodInvestorShare> rowsOf(List<PeriodInvestorShare> investors) => [
    for (final share in investors)
      if (!_isZero(share.amount) || !_isZero(share.expenses)) share,
  ];

  /// ما تحمّله بعلامة الطرح، وما رُدّ إليه بعلامة الجمع — العمودُ عمودُ ما يُطرح من الربح.
  static String _charged(String amount) {
    if (_isZero(amount)) return '0';

    return amount.startsWith('-') ? '+${amount.substring(1).grouped}' : '-${amount.grouped}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final hairline = BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5));
    final head = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final plain = context.textTheme.bodyMedium;
    final strong = plain?.copyWith(fontWeight: FontWeight.w800);

    Color? signed(String amount, {Color? otherwise}) =>
        amount.startsWith('-') ? scheme.error : otherwise;

    Color chargedColor(String amount) => _isZero(amount)
        ? scheme.onSurfaceVariant
        : amount.startsWith('-')
        ? scheme.primary
        : scheme.error;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Table(
        columnWidths: {
          0: const FlexColumnWidth(),
          1: FixedColumnWidth(72.w),
          2: FixedColumnWidth(68.w),
          3: FixedColumnWidth(72.w),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              _Cell('المستثمر', style: head),
              _Cell('الربح', style: head, atEnd: true),
              _Cell('المصاريف', style: head, atEnd: true),
              _Cell('الصافي', style: head, atEnd: true),
            ],
          ),
          for (final share in rowsOf(investors))
            TableRow(
              decoration: BoxDecoration(border: Border(top: hairline)),
              children: [
                _Cell(share.name, style: plain?.copyWith(fontWeight: FontWeight.w700)),
                _Cell.figure(
                  share.amount.grouped,
                  style: plain?.copyWith(
                    color: signed(share.amount, otherwise: scheme.onSurfaceVariant),
                  ),
                ),
                _Cell.figure(
                  _charged(share.expenses),
                  style: plain?.copyWith(color: chargedColor(share.expenses)),
                ),
                _Cell.figure(share.net.grouped, style: strong?.copyWith(color: signed(share.net))),
              ],
            ),
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant, width: 1.5)),
            ),
            children: [
              _Cell('المجموع', style: strong),
              _Cell.figure(
                totals.investorsTotal.grouped,
                style: plain?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: signed(totals.investorsTotal),
                ),
              ),
              _Cell.figure(
                _charged(totals.expensesOnInvestors),
                style: plain?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: chargedColor(totals.expensesOnInvestors),
                ),
              ),
              _Cell.figure(
                totals.net.grouped,
                style: strong?.copyWith(color: signed(totals.net, otherwise: scheme.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// خانةٌ في جدول المستثمرين: اسمٌ يلتفّ، أو رقمٌ في آخر خانته يصغر ولا يلتفّ.
class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.style, this.atEnd = false}) : isFigure = false;

  const _Cell.figure(this.text, {this.style}) : atEnd = true, isFigure = true;

  final String text;
  final TextStyle? style;
  final bool atEnd;
  final bool isFigure;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      maxLines: isFigure ? 1 : null,
      textDirection: isFigure ? TextDirection.ltr : null,
      style: style,
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(top: 10.h, bottom: 10.h, end: atEnd ? 0 : 8.w),
      child: atEnd
          ? Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FittedBox(fit: BoxFit.scaleDown, child: label),
            )
          : label,
    );
  }
}

/// ترتيبُ القائمة — زرٌّ بجانب عنوانها بدل صفِّ شرائح تحت البحث.
class _SortButton extends StatelessWidget {
  const _SortButton({required this.selected, required this.onSelected});

  final PeriodOrdersSort selected;
  final ValueChanged<PeriodOrdersSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PeriodOrdersSort>(
      tooltip: 'ترتيب',
      icon: Icon(AppIcons.sortBy),
      initialValue: selected,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final sort in PeriodOrdersSort.values)
          CheckedPopupMenuItem(value: sort, checked: sort == selected, child: Text(sort.label)),
      ],
    );
  }
}
