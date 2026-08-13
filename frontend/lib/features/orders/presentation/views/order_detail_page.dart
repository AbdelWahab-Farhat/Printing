import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_speed_dial.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:printing/features/orders/presentation/widgets/edit_shortages_sheet.dart';
import 'package:printing/features/orders/presentation/widgets/order_cost_section.dart';
import 'package:printing/features/orders/presentation/widgets/order_customer_card.dart';
import 'package:printing/features/orders/presentation/widgets/order_designs_section.dart';
import 'package:printing/features/orders/presentation/widgets/order_invoice_actions.dart';
import 'package:printing/features/orders/presentation/widgets/order_line_costs.dart';
import 'package:printing/features/orders/presentation/widgets/order_money_row.dart';
import 'package:printing/features/orders/presentation/widgets/order_status_bar.dart';
import 'package:printing/features/orders/presentation/widgets/order_timeline.dart';
import 'package:printing/features/orders/presentation/widgets/order_totals.dart';
import 'package:printing/features/orders/presentation/widgets/record_scrap_sheet.dart';
import 'package:printing/features/orders/usecases/record_scrap_loss.dart';
import 'package:printing/features/orders/usecases/set_order_shortages.dart';

/// One order, everything about it, and the moves staff make on it.
///
/// **The moves are drawn from `available_transitions` and from nothing else.** The server sends
/// that list already narrowed to what the signed-in user may do, so this screen holds no copy of
/// the state machine — no "if ready show dispatch", no permission checks of its own. Add a status
/// on the backend and it appears here without an app release; take a permission away and it
/// disappears. A second copy of those rules in Dart is the one that drifts, and it drifts on the
/// side that guards the button.
///
/// **The route is drawn once, at the bottom.** «سجل الحالات» already says where the order has
/// been and where it is; a rail across the top said the same thing a second time in a different
/// shape, and two answers to one question is one answer too many.
///
/// Pops with the updated [Order] when a move succeeded, so the list behind replaces its row
/// instead of re-fetching a page.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    // No ledger Cubit here: the entries live on their own screen, behind their own permission,
    // and this one never reads them. What it shows of the money — the three numbers in the
    // header — travels on the order's own payload.
    return BlocProvider<OrderDetailCubit>(
      create: (_) => sl<OrderDetailCubit>(param1: orderId)..load(),
      child: const _OrderDetailView(),
    );
  }
}

class _OrderDetailView extends StatefulWidget {
  const _OrderDetailView();

  @override
  State<_OrderDetailView> createState() => _OrderDetailViewState();
}

/// Stateful for one reason: it remembers whether anything was moved, so `pop` can hand the
/// result back. That is screen lifecycle, not business state — the Cubit owns the order itself.
class _OrderDetailViewState extends State<_OrderDetailView> {
  Order? _moved;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderDetailCubit>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Always through here, so the back button and the app bar's arrow return the same thing.
        context.pop(_moved);
      },
      child: Scaffold(
        // The dial pins to the edge that leaves room for its labels in Arabic — see
        // AppSpeedDial's own notes on why the three parts of that only work together.
        floatingActionButtonLocation: AppSpeedDial.location,
        floatingActionButton: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) {
            final order = state.order;
            if (order == null) return const SizedBox.shrink();

            return _Actions(
              order: order,
              onChangeStatus: _changeStatus,
              onEdit: _edit,
              onEditShortages: _editShortages,
              onOpenPayments: _openPayments,
            );
          },
        ),
        appBar: AppBar(
          title: BlocBuilder<OrderDetailCubit, OrderDetailState>(
            builder: (context, state) {
              final order = state.order;

              return Text(order == null ? 'تفاصيل الطلبية' : 'طلبية #${order.code}');
            },
          ),
        ),
        body: BlocConsumer<OrderDetailCubit, OrderDetailState>(
          listener: (context, state) {
            // Only when there is still a page underneath: with nothing to fall back to, the
            // body already shows the failure and a snackbar would say it twice.
            if (state case OrderDetailFailure(:final failure)) {
              if (state.order != null) context.showFailure(failure);
            }
          },
          builder: (context, state) => switch (state) {
            OrderDetailLoading() => const Center(child: CircularProgressIndicator()),
            OrderDetailFailure(:final failure) when state.order == null => _FailureView(
              message: failure.message,
              onRetry: cubit.load,
            ),
            _ => RefreshIndicator(
              onRefresh: cubit.load,
              child: _Body(
                order: state.order!,
                // A courtesy, never a boundary: the customer screen refuses on its own. Without
                // the grant the card still shows the three facts the order carries — it simply
                // stops advertising a door that opens onto a 403.
                onOpenCustomer: sl<Session>().can(AppPermission.viewCustomers)
                    ? _openCustomer
                    : null,
                // **`reports.pnl.view`, and there is no closer grant.** The API publishes the
                // cost side to anybody who may read the order, so this is the app choosing a
                // line rather than enforcing one — and the line it chooses is the one the
                // permission was written for: «هذه هي الشاشة التي تضع الإيراد والتكلفة جنباً
                // إلى جنب», which is a different sensitivity from being allowed to see either
                // alone. A clerk taking orders reads the invoice; what the bags cost us is not
                // part of that job.
                showCosts: sl<Session>().can(AppPermission.viewProfitAndLossReport),
                // `inventory.manage`, because scrapping draws stock and posts its FIFO cost —
                // it is a movement on the ledger, exactly like booking a shipment in, and the
                // route is guarded by that same grant rather than by any `orders.*` one.
                onScrap: sl<Session>().can(AppPermission.manageInventory) ? _recordScrap : null,
              ),
            ),
          },
        ),
      ),
    );
  }

  /// Hands the editing to its own screen, and re-reads whatever it changed.
  ///
  /// Re-read rather than trusting what came back: the totals are the server's arithmetic, an
  /// approved version changes what the order may do next, and this screen is the one that has
  /// to be right about both.
  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final changed = await context.push<bool>(Routes.editOrder(order.id));
    if (changed != true || !mounted) return;

    await cubit.load();

    final updated = cubit.state.order;
    if (updated != null) setState(() => _moved = updated);
  }

  /// Corrects what is missing, which corrects what the order costs.
  ///
  /// **A sheet rather than a screen**, because it is one number per line and no navigation: the
  /// store is standing over the delivery with the phone in one hand. The send happens here and
  /// not in the sheet, for the same reason every other form on this screen works that way — a
  /// form's answer is what was typed, and what to do about a refusal belongs to the screen that
  /// has somewhere to show it.
  ///
  /// Re-read afterwards rather than trusting what came back: the totals are the server's
  /// arithmetic, and this screen is the one that has to be right about them.
  Future<void> _editShortages(BuildContext context) async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    final lines = order?.items ?? const <OrderItem>[];
    if (order == null || lines.isEmpty) return;

    final shortages = await showEditShortagesSheet(context: context, items: lines);
    if (shortages == null || !mounted) return;

    final result = await sl<SetOrderShortages>()(order.id, shortages: shortages);
    if (!mounted) return;

    await result.fold(
      (failure) async => context.showFailure(failure),
      (_) async {
        await cubit.load();
        if (!mounted) return;

        final updated = cubit.state.order;
        if (updated != null) setState(() => _moved = updated);
      },
    );
  }

  /// Writes off bags that were ruined making this line.
  ///
  /// **Nothing is re-read afterwards, and that is not an oversight.** A scrap loss is a separate
  /// loss: it never touches the line's own `material_cost`, its `cogs`, or the order's
  /// `total_cogs`, so every number on this screen reads the same one moment later. What moved is
  /// the warehouse balance, and that is a different screen's business. Re-fetching here would
  /// teach the next reader that the totals shift, and one day somebody would build on it.
  ///
  /// The send happens here rather than in the sheet, for the same reason every other form on this
  /// screen works that way — a form's answer is what was typed, and what to do about a refusal
  /// belongs to the screen that has somewhere to show it. And there is a lot to show: «لا يمكن
  /// تسجيل تلف لطلبية لم تدخل مرحلة الطباعة بعد» and «الكمية المتوفرة في المخزن (٥٠) لا تكفي
  /// للكمية المطلوبة (٦٠)» are both the server's, both name what to do next, and neither could be
  /// written here without guessing at the shelf.
  Future<void> _recordScrap(BuildContext context, OrderItem item) async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final draft = await showRecordScrapSheet(context: context, item: item);
    if (draft == null || !mounted) return;

    final result = await sl<RecordScrapLoss>()(
      order.id,
      item.id,
      quantity: draft.quantity,
      notes: draft.notes,
    );

    if (!mounted) return;

    result.fold(
      // The server's own Arabic, with its field errors underneath it — «الكمية» carries both the
      // number asked for and the number available, which is the whole reason it is worth
      // rendering instead of a sentence of ours.
      (failure) => context.showFailure(failure),
      // The cost is the server's answer, not an echo of anything typed: the storekeeper counted
      // bags, and this is what those particular bags cost according to the batches they came out
      // of. It is the one number in the exchange nobody in the shop knew.
      (entry) => context.showSuccess(
        'سُجّل تلف بتكلفة ${entry.amount.grouped}',
        details: 'خُصمت الكمية من مخزن الطلبية — تكلفة البند وسعر الطلبية لم يتغيّرا',
      ),
    );
  }

  /// Hands the money to its own screen, and re-reads whatever it changed.
  ///
  /// Re-read rather than trusting a result: `paid_amount`, `remaining_amount` and
  /// `payment_status` live on the **order's** payload — they are what the three numbers at the
  /// top of this screen draw — and the ledger's page has no way to hand those back. Kept as
  /// `_moved` too, so backing out gives the list behind a row whose total is current.
  Future<void> _openPayments(BuildContext context) async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final changed = await context.push<bool>(Routes.orderPayments(order.id), extra: order.code);

    if (changed != true || !mounted) return;

    await cubit.load();

    if (!mounted) return;

    final updated = cubit.state.order;
    if (updated != null) setState(() => _moved = updated);
  }

  /// Opens the customer's own screen.
  ///
  /// The order carries the id whether or not the customer object came with it, so this works on
  /// a cold deep link too. Re-reads on the way back: an edit made over there — a corrected phone
  /// number, a deactivation — is exactly the sort of thing somebody does *because* of the order
  /// they were looking at.
  Future<void> _openCustomer() async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    await context.push(Routes.customer(order.customerId));
    if (!mounted) return;

    await cubit.load();
  }

  /// Hands the move to its own screen, and takes back whatever it did.
  ///
  /// **Nothing about the move is decided here.** The destinations, the fields each of them asks
  /// for and the request itself all belong to [OrderStatusPage]; this screen only learns the
  /// result — which it keeps, so backing out of it hands the updated order to the list behind.
  Future<void> _changeStatus(BuildContext context) async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final moved = await context.push<Order>(Routes.orderStatus(order.id));
    if (moved == null || !mounted) return;

    cubit.replace(moved);
    setState(() => _moved = moved);
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.order,
    required this.onOpenCustomer,
    required this.showCosts,
    required this.onScrap,
  });

  final Order order;

  /// Null for anybody without `customers.view` — see [OrderCustomerCard].
  final Future<void> Function()? onOpenCustomer;

  /// Whether what the job cost us is drawn at all — see the call site for which grant answers
  /// this and why it is that one.
  final bool showCosts;

  /// Null for anybody without `inventory.manage`.
  final Future<void> Function(BuildContext context, OrderItem item)? onScrap;

  /// Whether spoiling a bag is even possible yet.
  ///
  /// **The warehouse is the condition, not the status.** An order that has never entered «قيد
  /// الطباعة» has no shelf to draw from, and the server refuses with «لا يمكن تسجيل تلف لطلبية لم
  /// تدخل مرحلة الطباعة بعد» — a refusal worth never reaching, because the action would be
  /// offered on every order in the shop to no purpose.
  bool get _mayScrap => onScrap != null && order.fulfillmentWarehouseId != null;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Scrollable even when short, so pull-to-refresh works on every state.
      physics: const AlwaysScrollableScrollPhysics(),
      // Deep bottom padding: the floating dial hangs over this list, and a total it covers
      // is a number somebody has to move the screen to read.
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
      children: [
        // First, across the width, in the status's own colour. It is the question the screen is
        // opened to answer, and it used to be a chip the size of a list row's sharing a line
        // with the total.
        OrderStatusBar(status: order.status, label: order.statusLabel),
        // Directly under it, and that is the sequence rather than a spare slot: somebody who has
        // just read what state the order is in is one step from telling the customer so. Buried
        // on the dial it was a feature people forgot the app had.
        SizedBox(height: 12.h),
        CopyInvoiceButton(order: order),
        SizedBox(height: 16.h),
        _Header(order: order),
        SizedBox(height: 16.h),
        // Who it is for, and the way to them. Second, because "whose is this" is the question
        // asked right after "what state is it in" — and the phone number here is the one that
        // gets rung when either answer is a surprise.
        OrderCustomerCard(order: order, onTap: onOpenCustomer),
        // Moving the order lives on the floating button. Silence is not an explanation, so an
        // order that can go nowhere still says which of the two reasons applies: the dial is
        // simply not rendered, and a finished order and a user without the grant look identical
        // otherwise.
        if (!order.hasActions) ...[
          SizedBox(height: 16.h),
          _Note(
            text: order.isFinal
                ? 'الطلبية ${order.statusLabel} — لا مزيد من الإجراءات'
                : 'لا تملك صلاحية تغيير حالة هذه الطلبية',
          ),
        ],
        SizedBox(height: 16.h),
        _Destination(order: order),
        SizedBox(height: 16.h),
        if (order.items != null && order.items!.isNotEmpty) ...[
          _Section(
            title: 'البنود',
            child: _Items(
              items: order.items!,
              showCosts: showCosts,
              onScrap: _mayScrap ? onScrap : null,
            ),
          ),
          SizedBox(height: 16.h),
        ],
        _Section(
          title: 'الحساب',
          child: OrderTotals(order: order),
        ),
        // **Under «الحساب», never inside it.** What the customer pays is the question this screen
        // is opened to answer; what the job cost us is the quieter one asked afterwards, by fewer
        // people — see the grant at the call site — and mixing the two columns would put a figure
        // nobody reads out to a customer in the middle of the ones they do.
        if (showCosts) ...[
          SizedBox(height: 16.h),
          _Section(
            title: 'التكلفة والربح',
            child: OrderCostSection(order: order),
          ),
        ],
        // Shown even when no version exists yet, because that is exactly the order somebody
        // opens this screen to add one to. Any order may carry artwork — `design_source` says
        // whose work it was, which is a question about money, not about whether there is a file.
        if (order.designs != null) ...[
          SizedBox(height: 16.h),
          _Section(
            title: 'التصاميم',
            // Read here, changed on «تعديل الطلبية». Adding a version and judging one are both
            // edits, and this screen having its own copies of them would be a second door onto
            // the same room.
            child: OrderDesignsSection(designs: order.designs!),
          ),
        ],
        if (order.transitions != null && order.transitions!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _Section(
            title: 'سجل الحالات',
            child: OrderTimeline(records: order.transitions!),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // **Three numbers where «الإجمالي» used to stand alone.** The total on its own
          // answered one question; what it cost, what has been paid and what is left answer
          // the same one completely — and printing the total here *as well* would put the
          // order's value on this screen twice.
          //
          // Built from the order rather than from the ledger's Cubit: these three travel with
          // the order itself, so they are right for a reader who is not allowed to see the
          // entries behind them.
          OrderMoneyRow(
            summary: PaymentSummary(
              grandTotal: order.grandTotal,
              paidAmount: order.paidAmount,
              remainingAmount: order.remainingAmount,
              paymentStatus: order.paymentStatus,
              paymentStatusLabel: order.paymentStatusLabel,
              hasUnrecordedMoney: order.hasUnrecordedMoney,
            ),
          ),
          // Only ever present when it disagrees with the total above — that is the whole reason
          // the server records it — so it is drawn as a discrepancy rather than as a second
          // number in a list. Somebody reading this screen needs to see the gap, not hunt for it.
          if (order.collectedAmount case final collected?) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  'المستلم فعلياً',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.error,
                  ),
                ),
                const Spacer(),
                Text(
                  collected.grouped,
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.error,
                  ),
                ),
              ],
            ),
          ],
          // The customer used to be repeated here. They have their own card now, with the code
          // and a way into their file — three facts and a door, where this had two facts and
          // nowhere to go.
          if (order.cancellationReason case final reason?) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'سبب الإلغاء: $reason',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the floating button offers on this screen.
///
/// **One arm for the status, not one per status.** An order in «جاهزة» offers five moves, and a
/// dial with five arms covers the screen it is acting on. The arm opens the move on its own
/// screen, where the fields a destination asks for have room to be asked for.
///
/// The dial collapses to a plain button when only one entry survives, which is the common case
/// for a printer with one grant, and renders nothing at all when none does.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.order,
    required this.onChangeStatus,
    required this.onEdit,
    required this.onEditShortages,
    required this.onOpenPayments,
  });

  final Order order;
  final Future<void> Function(BuildContext context) onChangeStatus;
  final Future<void> Function(BuildContext context) onEdit;
  final Future<void> Function(BuildContext context) onEditShortages;
  final Future<void> Function(BuildContext context) onOpenPayments;

  /// Whether «تعديل الطلبية» has anything at all to offer this person.
  ///
  /// Three questions, each answered by the server's own flag and this user's own grant, and they
  /// close at three different moments: the lines when the bags exist, the artwork when the press
  /// starts, and the address only when somebody is already driving to it. An order in «جاهزة»
  /// has both of the first two shut and the third wide open — which is exactly the case that
  /// used to hide this button on a screen that had a section to offer.
  bool get _mayEditSomething =>
      (order.itemsAreEditable && sl<Session>().can(AppPermission.manageOrders)) ||
      (order.destinationIsEditable && sl<Session>().can(AppPermission.manageOrders)) ||
      (order.designsAreEditable && sl<Session>().can(AppPermission.manageOrderDesigns));

  @override
  Widget build(BuildContext context) {
    return AppSpeedDial(
      actions: [
        // No `permission` of its own: `available_transitions` arrives already narrowed to what
        // this user may do, and a second check in Dart could only disagree with the one that
        // matters.
        if (order.hasActions)
          AppAction(
            label: 'تغيير الحالة',
            icon: AppIcons.statusChange,
            tone: AppActionTone.primary,
            onTap: onChangeStatus,
          ),

        // Offered while *either* half of that screen is still open — the lines, or the artwork
        // — and they close at different points, which is why one flag could not answer for
        // both. The server owns both answers; this only stops offering a screen with nothing
        // on it to change.
        //
        // Checked here rather than declared as the action's `permission`, because it is an
        // *either*: a clerk holds `orders.manage` and a designer holds `orders.designs.manage`,
        // and each has something to do there the other has not.
        if (_mayEditSomething)
          AppAction(label: 'تعديل الطلبية', icon: AppIcons.edit, onTap: onEdit),

        // **Its own arm rather than a section of «تعديل الطلبية»**, because it is a different
        // act by a different person: the store counts what turned up, and the number they write
        // comes off the invoice. It costs the grant that declares a shortage in the first place.
        //
        // **Offered in «نواقص» and nowhere else.** That is the status the sheet is for — the job
        // is parked because the stock is not there — and the two moves either side of it already
        // ask the same question in the place it belongs: entering asks what is short, leaving
        // asks what arrived.
        if (order.shortagesAreEditable)
          AppAction(
            label: 'تعديل النواقص',
            icon: AppIcons.error,
            permission: AppPermission.moveOrderToShortage,
            onTap: onEditShortages,
          ),

        // The other half of «نسخ الفاتورة» — the same message, handed to the phone's own sheet
        // instead of to the clipboard. On the dial rather than beside the button, because the
        // clipboard is the one people reach for a dozen times a day and this is the one for
        // sending it straight on.
        //
        // No `permission`: it says nothing the reader is not already looking at, so a grant of
        // its own could only refuse somebody the screen has already shown everything to.
        AppAction(
          label: 'مشاركة الفاتورة',
          icon: AppIcons.share,
          onTap: (context) => shareOrderInvoice(context, order),
        ),

        // Its own screen, because a ledger gets long — see [OrderPaymentsPage]. The three
        // numbers stay at the top of *this* screen, so somebody checking «كم بقي» never has to
        // open it; the arm is for the people who write to the ledger and read its history.
        AppAction(
          label: 'الدفعات',
          icon: AppIcons.payment,
          permission: AppPermission.viewOrderPayments,
          onTap: onOpenPayments,
        ),

        AppAction(
          label: 'سجل التعديلات',
          icon: AppIcons.history,
          // `logs.view`, not `orders.view`, and that is the server's own line: a history shows
          // what everyone has done, including prices the reader may have no other way to see.
          permission: AppPermission.viewActivityLogs,
          onTap: (context) => context.push(Routes.activityLog(AuditSubject.order, order.id)),
        ),
      ],
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: order.isOfficePickup ? 'الاستلام' : 'التوصيل',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            icon: order.isOfficePickup ? AppIcons.warehouse : AppIcons.mapPin,
            label: order.fulfilmentTypeLabel,
            value: order.destination,
          ),
          if (order.customerShopName case final shop?)
            _Row(icon: AppIcons.warehouse, label: 'المحل', value: shop),
          if (order.addressDetails case final address?)
            _Row(icon: AppIcons.mapPin, label: 'العنوان', value: address),
          if (order.recipientName case final name?)
            _Row(icon: AppIcons.person, label: 'المستلم', value: name),
          if (order.recipientPhone case final phone?)
            _Row(icon: AppIcons.phone, label: 'هاتف المستلم', value: phone),
          if (order.trackingNumber case final tracking?)
            _Row(icon: AppIcons.tag, label: 'رقم التتبع', value: tracking),
          if (order.shippingCompany case final company?)
            _Row(icon: AppIcons.warehouse, label: 'شركة الشحن', value: company),
          if (order.weightKg case final weight?)
            _Row(icon: AppIcons.warehouse, label: 'الوزن', value: '$weight كجم'),
          if (order.notes case final notes?)
            _Row(icon: AppIcons.edit, label: 'ملاحظات', value: notes),
        ],
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.items, required this.showCosts, required this.onScrap});

  final List<OrderItem> items;

  /// Whether each line says what it cost to make, under what it is charged at.
  final bool showCosts;

  /// Null when scrapping is not on offer — no grant, or an order with no shelf behind it yet.
  final Future<void> Function(BuildContext context, OrderItem item)? onScrap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.productName} — ${item.variantLabel}',
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        // The quantity, its unit and the rate it was priced at — the three
                        // numbers somebody checking an invoice reads together.
                        //
                        // **The quantity here is the one being charged for**, so the line's own
                        // arithmetic comes out right on screen: «٢٠٠ قطعة × ١٫٥٥٠» beside
                        // «٣١٠٫٠٠». Printing the ordered 300 against a total built on 200 would
                        // make every short line look like a pricing error.
                        '${item.pricedQuantity.grouped} ${item.pricingUnitLabel} '
                        '× ${item.unitPrice.grouped}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      // On the line it is missing from, because that is the only place the
                      // number means anything: «ناقص ٤٠» of *which* size. What was ordered is
                      // said here too — it is no longer on the line above, and «ناقص من كم»
                      // is the question that follows «ناقص».
                      if (item.hasShortage) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'ناقص: ${item.shortageQuantity!.grouped} من ${item.quantity.grouped} '
                          '${item.pricingUnitLabel} — غير محتسب',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      // Under the price it is being charged at, quietly — see [OrderLineCosts]
                      // for why an uncosted line draws nothing here rather than «لم يُحتسب بعد».
                      if (showCosts) ...[
                        SizedBox(height: 2.h),
                        OrderLineCosts(item: item),
                      ],
                      // A text button rather than an arm on the dial: the dial acts on the
                      // *order*, and «أي بند تلف؟» is a question the row itself is the answer
                      // to. It is the same shape «إلغاء الدفعة» takes on a ledger row, for the
                      // same reason.
                      if (onScrap case final scrap?)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () => scrap(context, item),
                            icon: Icon(AppIcons.delete, size: 16.sp),
                            label: const Text('تسجيل تلف'),
                            style: TextButton.styleFrom(foregroundColor: scheme.error),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  item.lineTotal.grouped,
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17.sp, color: scheme.onSurfaceVariant),
          SizedBox(width: 10.w),
          Text(
            '$label: ',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Expanded(child: Text(value, style: context.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
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
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: scheme.error),
            SizedBox(height: 16.h),
            Text(
              // The server's own Arabic: it usually says what to do about it.
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 20.h),
            AppButton.tonal(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
