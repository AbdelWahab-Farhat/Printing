import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_tab_bar.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_review_queue_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_settlement_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_queue_filters.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_review_queue_tab.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_settlement_line.dart';
import 'package:dayaa/features/orders/presentation/widgets/settle_payments_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «مراجعة وتسوية الدفعات» — opened from its card under «حالات الدفع» on the home screen.
/// TREASURY-DESIGN §٢٣.
///
/// **تبويبان، والعددُ في اسم كلٍّ منهما** — قرار صاحب العمل ٢٠٢٦-١٠-٠٨: «تحتاج مراجعة» لمن يحمل
/// `orders.payments.review`، و«تحتاج تسوية» لمن يحمل `orders.payments.settle`. تبويبٌ واحد يُرسم
/// بلا شريط، كـ«المالية».
///
/// **في «تحتاج تسوية» مفتاحٌ: «بانتظار التسوية» / «مسوّاة»** — قائمتان بـCubit لكلٍّ منهما، فيحتفظ
/// كلٌّ بفلاتره وبحثه وموضعه حين يُبدَّل المفتاح. الأولى تُنشأ مع الصفحة لأنّ اسم التبويب يقرأ عددها؛
/// والثانية حين تُفتح أوّل مرة.
///
/// **والفلاتر فوق الصفوف وتمرّ معها** ([PaymentQueueFilters] في `PagedListView.header`): البحث،
/// وأزرار الفترة على «الكل»، و«من» / «إلى» والحساب أو النوع في الفلتر المتقدّم.
class PaymentSettlementPage extends StatelessWidget {
  const PaymentSettlementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();
    final canReview = session.can(AppPermission.reviewOrderPayments);
    final canSettle = session.can(AppPermission.settleOrderPayments);

    // The route lets nobody in who holds neither; this keeps a stray deep link from building a
    // provider list with nothing in it.
    if (!canReview && !canSettle) {
      return Scaffold(appBar: AppBar(title: const Text('مراجعة وتسوية الدفعات')));
    }

    return MultiBlocProvider(
      providers: [
        if (canReview) BlocProvider<PaymentReviewQueueCubit>(create: (_) => sl<PaymentReviewQueueCubit>()..load()),
        if (canSettle)
          BlocProvider<PaymentSettlementCubit>(
            create: (_) => sl<PaymentSettlementCubit>(param1: SettlementState.pending)..start(),
          ),
      ],
      child: _Desk(canReview: canReview, canSettle: canSettle),
    );
  }
}

class _Desk extends StatelessWidget {
  const _Desk({required this.canReview, required this.canSettle});

  final bool canReview;
  final bool canSettle;

  /// «تحتاج مراجعة (٥)» — the count once the server has answered, and only when it is not zero.
  static String _named(String name, int? count) => count == null || count == 0 ? name : '$name ($count)';

  @override
  Widget build(BuildContext context) {
    // Watched only where the tab exists — reading a Cubit nobody provided would throw.
    final waitingReview = canReview ? context.select((PaymentReviewQueueCubit c) => c.waiting) : null;
    final waitingSettle = canSettle ? context.select((PaymentSettlementCubit c) => c.count) : null;

    final tabs = <(String, Widget)>[
      if (canReview) (_named('تحتاج مراجعة', waitingReview), const _KeptAlive(child: PaymentReviewQueueTab())),
      if (canSettle) (_named('تحتاج تسوية', waitingSettle), const _KeptAlive(child: _SettlementTab())),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة وتسوية الدفعات')),
      body: switch (tabs) {
        [(_, final only)] => only,
        _ => DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              AppTabBar(labels: [for (final (label, _) in tabs) label]),
              Expanded(child: TabBarView(children: [for (final (_, body) in tabs) body])),
            ],
          ),
        ),
      },
    );
  }
}

/// «تحتاج تسوية»: «بانتظار التسوية» and «مسوّاة» behind one switch at the top of each list.
class _SettlementTab extends StatefulWidget {
  const _SettlementTab();

  @override
  State<_SettlementTab> createState() => _SettlementTabState();
}

class _SettlementTabState extends State<_SettlementTab> {
  SettlementState _shown = SettlementState.pending;

  /// The settled list is built — and asks the server — the first time it is shown, not before.
  bool _settledOpened = false;

  void _show(SettlementState value) => setState(() {
    _shown = value;
    if (value == SettlementState.settled) _settledOpened = true;
  });

  @override
  Widget build(BuildContext context) {
    final toggle = _ListSwitch(shown: _shown, onChanged: _show);

    // Both kept mounted, so each list's filters, search and scroll survive the switch.
    return IndexedStack(
      index: _shown.index,
      children: [
        _SettlementList(top: toggle),
        if (_settledOpened)
          BlocProvider<PaymentSettlementCubit>(
            create: (_) => sl<PaymentSettlementCubit>(param1: SettlementState.settled)..start(),
            child: _SettlementList(top: toggle),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

/// «بانتظار التسوية» | «مسوّاة» — the app's segmented control, the full width like every field
/// under it.
class _ListSwitch extends StatelessWidget {
  const _ListSwitch({required this.shown, required this.onChanged});

  final SettlementState shown;
  final ValueChanged<SettlementState> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SettlementState>(
      key: const ValueKey('settlement-switch'),
      segments: [
        for (final state in SettlementState.values)
          ButtonSegment<SettlementState>(value: state, label: Text(state.label)),
      ],
      selected: {shown},
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      onSelectionChanged: (choice) => onChanged(choice.first),
    );
  }
}

class _SettlementList extends StatefulWidget {
  const _SettlementList({required this.top});

  /// The switch between the two lists, drawn at the top of the header.
  final Widget top;

  @override
  State<_SettlementList> createState() => _SettlementListState();
}

class _SettlementListState extends State<_SettlementList> {
  /// The payments ticked for settling together, by id — kept across pages as more load.
  final Map<int, OrderPayment> _selected = {};

  bool _busy = false;

  PaymentSettlementCubit get _cubit => context.read<PaymentSettlementCubit>();

  /// Every filter change clears the ticks: a payment ticked under «النورس» and then hidden by
  /// «مصرف علي» would be settled without anybody seeing it.
  Future<void> _refilter(Future<void> Function() change) async {
    setState(_selected.clear);
    await change();
  }

  void _toggle(OrderPayment payment) {
    setState(() {
      if (_selected.remove(payment.id) == null) _selected[payment.id] = payment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentSettlementCubit, PaymentSettlementState>(
      builder: (context, state) => Column(
        children: [
          Expanded(
            child: PagedListView<OrderPayment>(
              state: state,
              header: PaymentQueueFilters(
                top: widget.top,
                period: _cubit.period,
                onPeriod: (period) => unawaited(_refilter(() => _cubit.showPeriod(period))),
                onSearch: _cubit.search,
                isAdvancedActive: _cubit.hasAdvanced,
                onAdvanced: () => unawaited(_advanced()),
              ),
              emptyMessage: _cubit.tab == SettlementState.pending
                  ? 'لا دفعات بانتظار التسوية'
                  : 'لا دفعات مسوّاة في هذه الفترة',
              onLoadMore: _cubit.loadMore,
              onRefresh: _cubit.refresh,
              skeletonHeight: 96.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, payment, index) => _Row(
                key: ValueKey(payment.id),
                payment: payment,
                isBusy: _busy,
                isSelected: _selected.containsKey(payment.id),
                // Ticking is for the waiting list; a settled row has only its «تراجع».
                onToggle: _cubit.tab == SettlementState.pending && payment.canSettle
                    ? () => _toggle(payment)
                    : null,
                onOpen: () => unawaited(_open(payment)),
                onSettle: () => unawaited(_settle([payment])),
                onUnsettle: () => unawaited(_unsettle(payment)),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            _SelectionBar(
              selected: _selected.values.toList(growable: false),
              onClear: () => setState(_selected.clear),
              onSettle: () => unawaited(_settle(_selected.values.toList(growable: false))),
            ),
        ],
      ),
    );
  }

  /// «من» / «إلى» and where the money waits. The accounts are asked again if the first answer
  /// never came, so the field is never empty for want of a retry.
  Future<void> _advanced() async {
    if (_cubit.accounts.value == null) await _cubit.loadAccounts();

    if (!mounted) return;

    final range = _cubit.customRange;
    final chosen = await showPaymentAdvancedFilter(
      context: context,
      current: PaymentAdvancedFilter(from: range?.from, to: range?.to, accountId: _cubit.accountId),
      accounts: _cubit.accounts.value?.sources ?? const <SettlementAccount>[],
    );

    if (chosen == null || !mounted) return;

    await _refilter(
      () => _cubit.applyAdvanced(from: chosen.from, to: chosen.to, accountId: chosen.accountId),
    );
  }

  /// The order's own payments, where the receipt and every other entry are. Re-read on the way
  /// back: a settlement made there moves this list too.
  Future<void> _open(OrderPayment payment) async {
    await context.pushForResult<bool>(
      Routes.orderPayments(payment.orderId),
      extra: payment.order?.code ?? '',
    );

    if (mounted) unawaited(_cubit.refresh());
  }

  Future<void> _settle(List<OrderPayment> payments) async {
    if (_cubit.accounts.value == null) await _cubit.loadAccounts();

    if (!mounted) return;

    final destinations = _cubit.accounts.value?.destinations;

    if (destinations == null) {
      context.showError('تعذّر تحميل الحسابات — حاول مجدداً');

      return;
    }

    final saved = await showSettlePaymentsSheet(
      context: context,
      payments: payments,
      destinations: destinations,
      onSubmit: (rows, accountId) => _cubit.settle(rows, accountId: accountId),
    );

    if (saved != true || !mounted) return;

    setState(_selected.clear);
    context.showSuccess(payments.length == 1 ? 'تمت تسوية الدفعة' : 'تمت تسوية الدفعات');
  }

  Future<void> _unsettle(OrderPayment payment) async {
    final reason = await askUnsettleReason(context, payment);

    if (reason == null || !mounted) return;

    setState(() => _busy = true);

    final failure = await _cubit.unsettle(payment, reason: reason);

    if (!mounted) return;

    setState(() => _busy = false);

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess('أُلغيت تسوية الدفعة');
  }
}

/// One payment: the order, how much, how and when, where it is now — and what can be done.
class _Row extends StatelessWidget {
  const _Row({
    required this.payment,
    required this.isBusy,
    required this.isSelected,
    required this.onToggle,
    required this.onOpen,
    required this.onSettle,
    required this.onUnsettle,
    super.key,
  });

  final OrderPayment payment;
  final bool isBusy;
  final bool isSelected;
  final VoidCallback? onToggle;
  final VoidCallback onOpen;
  final VoidCallback onSettle;
  final VoidCallback onUnsettle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final order = payment.order;

    return InkWell(
      onTap: onOpen,
      onLongPress: onToggle,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onToggle != null)
                  Checkbox(
                    key: ValueKey('select-${payment.id}'),
                    value: isSelected,
                    onChanged: (_) => onToggle!(),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(top: 2.h, left: 4.w, right: 4.w),
                    child: Icon(AppIcons.payment, size: 18.sp, color: scheme.primary),
                  ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          if (order != null) '#${order.code}',
                          if (order?.customerName case final name? when name.isNotEmpty) name,
                        ].join(' · '),
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        [
                          if (payment.methodLabel case final label? when label.isNotEmpty) label,
                          if (payment.paidAt case final paidAt?) paidAt.dayLabel,
                          if (payment.recordedBy case final recorder?) recorder.name,
                        ].join(' · '),
                        style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  payment.amount.grouped,
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 40.w, top: 4.h),
              child: PaymentSettlementLine(
                payment: payment,
                isBusy: isBusy,
                onSettle: onSettle,
                onUnsettle: onUnsettle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «تسوية المحدد (٤)» at the foot of the waiting list, while anything is ticked.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.selected,
    required this.onClear,
    required this.onSettle,
  });

  final List<OrderPayment> selected;
  final VoidCallback onClear;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: Row(
          children: [
            IconButton(
              tooltip: 'إلغاء التحديد',
              onPressed: onClear,
              icon: Icon(AppIcons.close),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: AppButton(
                key: const ValueKey('settle-selected'),
                label: 'تسوية المحدد (${selected.length})',
                icon: AppIcons.transfer,
                onPressed: onSettle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps a tab's list mounted after it is swiped away — the reason the المخزون tab gives:
/// each tab builds its own Cubit, and without this every swipe would re-fetch the list, empty
/// the search box and lose the scroll.
class _KeptAlive extends StatefulWidget {
  const _KeptAlive({required this.child});

  final Widget child;

  @override
  State<_KeptAlive> createState() => _KeptAliveState();
}

class _KeptAliveState extends State<_KeptAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return widget.child;
  }
}
