import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/carrier/usecases/lodge_order.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_filter_button.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_sort_button.dart';
import 'package:dayaa/features/orders/presentation/widgets/send_together.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الطلبيات — the work queue.
///
/// A body, not a screen: the app bar and the tabs belong to the shell above it.
///
/// **No "new order" button yet, and that is a stated gap rather than an oversight.** Taking an
/// order is a form with a customer, a destination, and a priced line per product — its own
/// slice, recorded in BACKLOG.md. What is here is what makes the workflow usable: seeing the
/// queues and moving orders through them.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>(
      create: (_) => sl<OrdersCubit>()..load(),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatefulWidget {
  const _OrdersView();

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

/// Stateful for one reason: **picking orders to send together** is this screen's own moment,
/// not the list's. What is picked is gone the second the screen is, and holding it in the Cubit
/// would put a checkbox's state beside the pages it has nothing to do with.
class _OrdersViewState extends State<_OrdersView> {
  bool _picking = false;
  bool _sending = false;

  /// In the order they were picked — the first one is what the rest are compared against.
  final Map<int, Order> _picked = {};

  /// Whether «إرسال معاً للنورس» is on offer: the grant, and a queue whose orders are one step
  /// from the road. Anywhere else every card would be dimmed, which is a mode with nothing in it.
  bool _mayPick(OrdersCubit cubit) =>
      sl<Session>().can(AppPermission.manageCarrierParcels) &&
      (cubit.status == OrderStatus.ready || cubit.status == OrderStatus.resend);

  void _stopPicking() => setState(() {
    _picking = false;
    _picked.clear();
  });

  void _toggle(Order order) => setState(() {
    if (_picked.remove(order.id) == null) _picked[order.id] = order;
  });

  /// Asks, sends, and says what came back.
  ///
  /// **Asked first, like the single «إرسال للنورس»** — this creates a parcel in the carrier's
  /// system, and an accidental tap is undone by phoning them. The dialog names every order and
  /// the destination, the two facts worth checking before a courier is sent.
  ///
  /// **No order moves.** They stay in «جاهزة» until Nawris reports the courier holding the
  /// parcel, and then all of them move together — so the list is re-read for the parcel code on
  /// each card, not for a status.
  Future<void> _send(OrdersCubit cubit) async {
    final orders = _picked.values.toList(growable: false);
    final first = orders.first;
    final destination = [first.cityName, ?first.regionName].join(' — ');

    final confirmed = await showCustomDialog(
      context: context,
      title: 'إرسال ${orders.length.grouped} طلبيات في طرد واحد؟',
      description:
          'ستُنشأ شحنة واحدة لدى النورس إلى $destination، تضم: '
          '${orders.map((o) => o.code).join('، ')}.\n\n'
          'يُسلَّم الطرد أو يُرجَع كاملاً، ولا يمكن إخراج طلبية منه بعد الإرسال.',
      confirmLabel: 'إرسال',
    );

    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _sending = true);

    final result = await sl<LodgeOrdersTogether>()(
      orders.map((o) => o.id).toList(growable: false),
    );

    if (!mounted) return;

    setState(() => _sending = false);

    result.fold(
      // The server's own Arabic — it names the order that does not fit, which is the one thing
      // the clerk needs to unpick.
      (failure) => context.showFailure(failure),
      (parcel) {
        context.showSuccess(
          'أُرسلت ${orders.length.grouped} طلبيات في طرد واحد — رقم الشحنة ${parcel.code}',
          details: [
            if (parcel.amountToCollect case final amount?) 'المطلوب تحصيله ${amount.grouped}',
            'الحالة تبقى «جاهزة» حتى يستلمها المندوب',
          ].join(' · '),
        );
        _stopPicking();
        cubit.refresh().ignore();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrdersCubit>();

    return Scaffold(
      // Transparent: the shell above owns the real Scaffold.
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _picking
          ? SendTogetherBar(
              count: _picked.length,
              isSending: _sending,
              onSend: () => _send(cubit),
              onCancel: _stopPicking,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Row(
              children: [
                // One box, three questions. What was typed decides which one it is, and that
                // decision is the server's — duplicating the rule here would give the hint and
                // the results two chances to disagree. The hint's job is to say the box accepts
                // all three, not to classify.
                Expanded(
                  child: SearchField(
                    hint: 'رقم الطلبية · كود العميل · رقم الهاتف',
                    onChanged: cubit.search,
                  ),
                ),
                SizedBox(width: 10.w),
                // Both rebuilt with the list, so what the sheet says is ticked — and which way
                // the arrow points — cannot disagree with what is on screen.
                BlocBuilder<OrdersCubit, OrdersState>(
                  builder: (context, state) => Row(
                    children: [
                      if (_mayPick(cubit)) ...[
                        _PickButton(
                          active: _picking,
                          onPressed: _picking
                              ? _stopPicking
                              : () => setState(() => _picking = true),
                        ),
                        SizedBox(width: 6.w),
                      ],
                      // **A button, not a row on the filter sheet.** The sort narrows nothing,
                      // and one tap is the whole of it — see [OrderSortButton].
                      OrderSortButton(sort: cubit.sort, onToggled: cubit.showSort),
                      SizedBox(width: 6.w),
                      OrderFilterButton(
                        selected: cubit.status,
                        selectedPayments: cubit.paymentStatuses,
                        selectedUrgency: cubit.isUrgent,
                        counts: cubit.counts,
                        onApplied: (status, payments, isUrgent) {
                          // Picking belongs to the queue it started in: the picks may not
                          // even be on the next one.
                          if (_picking && status != cubit.status) _stopPicking();
                          cubit
                              .showFilters(
                                status: status,
                                paymentStatuses: payments,
                                isUrgent: isUrgent,
                              )
                              .ignore();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) => PagedListView<Order>(
                state: state,
                emptyMessage: 'لا توجد طلبيات في هذه القائمة',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // The measured height of a card: the status band and three rows of labelled
                // facts, with the space the reference card keeps between them.
                skeletonHeight: 380.h,
                itemBuilder: (context, order, index) => _picking
                    ? PickableOrderCard(
                        key: ValueKey(order.id),
                        order: order,
                        picked: _picked.containsKey(order.id),
                        blockedBecause: whyNotSendTogether(
                          order,
                          first: _picked.values.firstOrNull,
                        ),
                        onToggle: () => _toggle(order),
                      )
                    : OrderCard(
                        key: ValueKey(order.id),
                        order: order,
                        onTap: () async {
                          // The detail screen hands back the order if it moved it, so the row
                          // updates without a round trip — and drops out of the list when it no
                          // longer belongs to the queue on screen.
                          final moved = await context.pushForResult<Order>(
                            Routes.order(order.id),
                          );
                          if (moved != null) cubit.replace(moved);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «إرسال معاً للنورس» — enters picking, and leaves it. Drawn like [OrderSortButton] beside it,
/// and filled while picking so the mode is visible from the header too.
class _PickButton extends StatelessWidget {
  const _PickButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Tooltip(
      message: active ? 'إلغاء الاختيار' : 'إرسال معاً للنورس',
      child: Material(
        color: active ? scheme.primaryContainer : scheme.surfaceContainerLowest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(13.w),
            child: Icon(
              active ? AppIcons.close : AppIcons.sharedParcel,
              size: 22.sp,
              color: active ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
