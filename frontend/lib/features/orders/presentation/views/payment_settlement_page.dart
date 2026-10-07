import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_tab_bar.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_settlement_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_settlement_line.dart';
import 'package:dayaa/features/orders/presentation/widgets/settle_payments_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/settlement_account_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «تسوية الدفعات» — opened from «المالية» in the drawer. TREASURY-DESIGN §٢٣.
///
/// **The money moves when it really arrives, not when the order is closed.** Nawris pays a week
/// of parcels in one transfer, a customer's transfer lands in «مصرف علي» days before the order is
/// settled — this page carries each payment's money to where it really is, one at a time or a
/// whole transfer's worth together, and takes it back when somebody got it wrong.
///
/// **Two tabs, drawn and swiped like المخزون's** ([AppTabBar] over a [TabBarView]): «بانتظار
/// التسوية» — money still where it landed, oldest first — and «مسوّاة», newest first, each with
/// its «تراجع». Each tab is its own list with its own Cubit, so its filters, search and scroll
/// survive a swipe to the other and back.
class PaymentSettlementPage extends StatelessWidget {
  const PaymentSettlementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسوية الدفعات')),
      body: DefaultTabController(
        length: SettlementState.values.length,
        child: Column(
          children: [
            AppTabBar(labels: [for (final tab in SettlementState.values) tab.label]),
            Expanded(
              child: TabBarView(
                children: [
                  for (final tab in SettlementState.values) _KeptAlive(child: _SettlementTab(tab: tab)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tab: its own Cubit, asking the server for one of the two lists.
class _SettlementTab extends StatelessWidget {
  const _SettlementTab({required this.tab});

  final SettlementState tab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaymentSettlementCubit>(
      create: (_) => sl<PaymentSettlementCubit>(param1: tab)..start(),
      child: const _SettlementList(),
    );
  }
}

class _SettlementList extends StatefulWidget {
  const _SettlementList();

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
          _Filters(onRefilter: _refilter),
          _Summary(cubit: _cubit),
          Expanded(
            child: PagedListView<OrderPayment>(
              state: state,
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

/// The period, the search box, and where the money waits.
class _Filters extends StatelessWidget {
  const _Filters({required this.onRefilter});

  final Future<void> Function(Future<void> Function() change) onRefilter;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentSettlementCubit>();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wraps rather than scrolls: a chip pushed off the edge — «من – إلى» on a phone — is a
          // filter nobody finds.
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final period in SettlementPeriod.values)
                FilterOptionChip(
                  key: ValueKey('period-${period.name}'),
                  label: _periodLabel(cubit, period),
                  isSelected: cubit.period == period,
                  onTap: () => unawaited(_choosePeriod(context, period)),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          SearchField(
            key: const ValueKey('settlement-search'),
            hint: 'ابحث برقم الطلبية أو اسم الزبون',
            onChanged: cubit.search,
          ),
          SizedBox(height: 8.h),
          ValueListenableBuilder<SettlementAccounts?>(
            valueListenable: cubit.accounts,
            builder: (context, accounts, _) => _AccountField(
              accounts: accounts?.sources ?? const <SettlementAccount>[],
              selectedId: cubit.accountId,
              onChosen: (id) => unawaited(onRefilter(() => cubit.showAccount(id))),
            ),
          ),
        ],
      ),
    );
  }

  /// «من – إلى» names its two days once they are chosen.
  static String _periodLabel(PaymentSettlementCubit cubit, SettlementPeriod period) {
    final range = cubit.customRange;

    if (period != SettlementPeriod.custom || range == null) return period.label;

    return '${range.from.dayLabel} – ${range.to.dayLabel}';
  }

  Future<void> _choosePeriod(BuildContext context, SettlementPeriod period) async {
    final cubit = context.read<PaymentSettlementCubit>();

    if (period != SettlementPeriod.custom) {
      return onRefilter(() => cubit.showPeriod(period));
    }

    final now = DateTime.now();
    final current = cubit.customRange;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: current == null ? null : DateTimeRange(start: current.from, end: current.to),
    );

    if (picked == null) return;

    await onRefilter(
      () => cubit.showPeriod(SettlementPeriod.custom, between: (from: picked.start, to: picked.end)),
    );
  }
}

/// «الحساب: النورس» — a field that opens a searchable list of where payments wait, with a cross
/// to go back to every account. The owner's choice over a row of chips (2026-10-07).
class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.accounts,
    required this.selectedId,
    required this.onChosen,
  });

  final List<SettlementAccount> accounts;
  final int? selectedId;
  final ValueChanged<int?> onChosen;

  @override
  Widget build(BuildContext context) {
    final selected = accounts.where((a) => a.id == selectedId).firstOrNull;

    return AppTextField(
      // Keyed on the choice: the field shows a value it was handed, and a new choice is a new
      // value rather than an edit to the old one.
      key: ValueKey('settlement-account-${selectedId ?? 'all'}'),
      initialValue: selected?.name ?? 'كل الحسابات',
      label: 'الحساب',
      prefixIcon: AppIcons.treasury,
      readOnly: true,
      enabled: accounts.isNotEmpty,
      suffix: selected == null
          ? null
          : IconButton(
              tooltip: 'كل الحسابات',
              onPressed: () => onChosen(null),
              icon: Icon(AppIcons.close),
            ),
      onTap: () async {
        final choice = await showSettlementAccountPicker(
          context: context,
          accounts: accounts,
          selectedId: selectedId,
        );

        if (choice != null) onChosen(choice.accountId);
      },
    );
  }
}

/// «١٢ دفعة · ٣٬٤٠٠٫٠٠» — the server's count and total for everything that matched.
class _Summary extends StatelessWidget {
  const _Summary({required this.cubit});

  final PaymentSettlementCubit cubit;

  @override
  Widget build(BuildContext context) {
    final count = cubit.count;

    if (count == null) return SizedBox(height: 8.h);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 6.h),
      child: Row(
        children: [
          Icon(
            cubit.tab == SettlementState.pending ? AppIcons.transfer : AppIcons.settled,
            size: 18.sp,
            color: context.colorScheme.tertiary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${cubit.tab.label}: $count',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            cubit.amountTotal.grouped,
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
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
