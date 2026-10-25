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
        _Pool(totals: held.totals),
        if (held.orders.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _Tiles(
            filters: _filtersFor(held),
            totals: held.totals.byState,
            selected: loaded.filter,
            onTap: cubit.filterBy,
          ),
        ],
        if (held.investors.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _ListCard(
            title: 'المستثمرون',
            rows: [for (final share in held.investors) _LedgerRow(share: share)],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ربح المستثمرين',
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${totals.investorsTotal.grouped} د.ل',
          textDirection: TextDirection.ltr,
          style: context.textTheme.headlineMedium?.copyWith(
            color: isNegative ? scheme.error : scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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

/// شريكٌ ومجموعُ ما أخذه من طلبيات الفترة.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.share});

  final PeriodInvestorShare share;

  /// سؤالُ المستثمر نفسُه: «كم وصلني من هذه الفترة، وكم بقي» — ما ليس صفراً وحده.
  ///
  /// **وجزءٌ واحدٌ من الدفتر لا يُكتب**: هو الرقمُ نفسُه على يساره («ينتظر 1,050.41» تحت
  /// «1,050.41 د.ل»). وما في الطريق يُكتب دائماً، لأنه ليس في ذلك الرقم.
  String? get _split {
    final released = !_isZero(share.released);
    final pending = !_isZero(share.pending);
    final expected = !_isZero(share.expected);

    if (!expected && !(released && pending)) return null;

    return [
      if (released) 'استُلم ${share.released.grouped}',
      if (pending) 'ينتظر ${share.pending.grouped}',
      if (expected) 'في الطريق ${share.expected.grouped}',
    ].join(' · ');
  }

  static bool _isZero(String amount) => (double.tryParse(amount) ?? 0) == 0;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final split = _split;
    final letters = share.name.trim().characters;
    final initial = letters.isEmpty ? '؟' : letters.first;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: scheme.secondaryContainer,
            child: Text(
              initial,
              style: context.textTheme.bodyLarge?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.name,
                  style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (split != null)
                  Text(
                    split,
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '${share.amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: share.amount.startsWith('-') ? scheme.error : null,
            ),
          ),
        ],
      ),
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
