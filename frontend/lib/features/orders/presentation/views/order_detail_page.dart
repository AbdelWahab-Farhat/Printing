// `show Either` rather than `hide Order`: dartz also exports a `State`, and in a widget file
// that one collides with Flutter's. Only the one type this file names is taken.
import 'package:dartz/dartz.dart' show Either;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/carrier/models/nawris_parcel.dart';
import 'package:dayaa/features/carrier/usecases/lodge_order.dart';
import 'package:dayaa/features/carrier/usecases/release_shipment.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/edit_shortages_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_cost_section.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_customer_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_designs_section.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_detail_header.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_invoice_actions.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_item_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_money_row.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_timeline.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_totals.dart';
import 'package:dayaa/features/orders/presentation/widgets/record_scrap_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/reinstate_order_dialog.dart';
import 'package:dayaa/features/orders/usecases/record_scrap_loss.dart';
import 'package:dayaa/features/orders/usecases/set_order_shortages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One order, everything about it, and the moves staff make on it.
///
/// **The moves are drawn from `available_transitions` and from nothing else.** The server sends
/// that list already narrowed to what the signed-in user may do, so this screen holds no copy of
/// the state machine — no "if ready show dispatch", no permission checks of its own. Add a status
/// on the backend and it appears here without an app release; take a permission away and it
/// disappears. A second copy of those rules in Dart is the one that drifts, and it drifts on the
/// side that guards the button.
///
/// **The screen begins with its header rather than with a stack of cards.** Which order this
/// is, whose it is, what state it is in and where it goes are the four facts every visit starts
/// with; they are pinned to the bar — see [OrderDetailHeader] — and the list underneath opens on
/// the invoice instead of scrolling past them.
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
        // No `appBar`: the order's own header *is* the bar — see [OrderDetailHeader] — and it
        // needs the order to draw itself. The two states that have no order yet put a plain one
        // of their own on top, so «رجوع» is never missing.
        body: BlocConsumer<OrderDetailCubit, OrderDetailState>(
          listener: (context, state) {
            // Only when there is still a page underneath: with nothing to fall back to, the
            // body already shows the failure and a snackbar would say it twice.
            if (state case OrderDetailFailure(:final failure)) {
              if (state.order != null) context.showFailure(failure);
            }
          },
          builder: (context, state) => switch (state) {
            OrderDetailLoading() => const _BeforeTheOrder(
              child: Center(child: CircularProgressIndicator()),
            ),
            OrderDetailFailure(:final failure) when state.order == null => _BeforeTheOrder(
              child: _FailureView(message: failure.message, onRetry: cubit.load),
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
                // The same courtesy the customer card is given, and the same grant logic: the
                // product screen refuses on its own, so this only decides whether a door is
                // advertised. Without `products.view` the line still names what was sold.
                onOpenProduct: sl<Session>().can(AppPermission.viewProducts) ? _openProduct : null,
                // **`reports.pnl.view`, and there is no closer grant.** The API publishes the
                // cost side to anybody who may read the order, so this is the app choosing a
                // line rather than enforcing one — and the line it chooses is the one the
                // permission was written for: «هذه هي الشاشة التي تضع الإيراد والتكلفة جنباً
                // إلى جنب», which is a different sensitivity from being allowed to see either
                // alone. A clerk taking orders reads the invoice; what the bags cost us is not
                // part of that job.
                showCosts: sl<Session>().can(AppPermission.viewProfitAndLossReport),
                // **`products.view_cost`, and this one *is* enforced by the API**: the vendor's
                // figures on a وسيط line are omitted from the payload without it, so the grant
                // is checked rather than the null — a null here also means «not a وسيط line».
                // The same grant that guards the catalogue number the line's cost was copied
                // from, because hiding a figure on one screen and sending it on another is a
                // lock on one door of two.
                showOutsourcingCosts: sl<Session>().can(AppPermission.viewProductCost),
                // `inventory.manage`, because scrapping draws stock and posts its FIFO cost —
                // it is a movement on the ledger, exactly like booking a shipment in, and the
                // route is guarded by that same grant rather than by any `orders.*` one.
                onScrap: sl<Session>().can(AppPermission.manageInventory) ? _recordScrap : null,
                // Always offered, unlike a sheet that could only ever show the order's own
                // note: the page gathers what was written at every status too, and «لا توجد
                // ملاحظات» is an answer worth reaching rather than a button that vanished.
                onOpenNotes: _openNotes,
                // `logs.view`, not `orders.view`, and that is the server's own line: a history
                // shows what everyone has done, including prices the reader may have no other
                // way to see.
                onOpenLog: sl<Session>().can(AppPermission.viewActivityLogs) ? _openLog : null,
                // «إرسال للنورس». `carrier.manage` is the grant — a different one from
                // `orders.manage`, because handing goods to a courier is not editing paperwork.
                // The other two conditions are the order's own and are read in [_Body].
                onSendToCarrier: sl<Session>().can(AppPermission.manageCarrierParcels)
                    ? _sendToCarrier
                    : null,
                onResendShipment: sl<Session>().can(AppPermission.manageCarrierParcels)
                    ? _resendShipment
                    : null,
                onDeleteShipment: sl<Session>().can(AppPermission.manageCarrierParcels)
                    ? _deleteShipment
                    : null,
                onUnlinkShipment: sl<Session>().can(AppPermission.manageCarrierParcels)
                    ? _unlinkShipment
                    : null,
                // **Not gated here, and that is the point.** Whether the undo is on offer is
                // three conditions the server already answered — cancelled, granted, and a
                // timeline that records what it was cancelled from — and it sent the answer as
                // `reinstateTo`. A permission check in Dart beside it would be a fourth opinion
                // with nothing keeping it honest.
                onReinstate: state.order!.canReinstate ? _reinstate : null,
              ),
            ),
          },
        ),
      ),
    );
  }

  /// Hands the order to Nawris.
  ///
  /// **Asked first, because this one leaves the building.** Every other button on this screen
  /// writes to our own database; this creates a parcel in the carrier's system, and an accidental
  /// tap is undone by phoning them. The dialog names the destination, which is the fact worth
  /// checking before a courier is sent to it.
  ///
  /// **The order's status is deliberately left alone.** It stays «جاهزة» until Nawris reports a
  /// courier is holding the parcel, and their webhook moves it then — see `NawrisStatusCode`
  /// case 4. Advancing it here would be this screen claiming a journey had begun on the strength
  /// of an API call.
  Future<void> _sendToCarrier() async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final destination = [order.cityName, ?order.regionName].join(' — ');

    final confirmed = await showCustomDialog(
      context: context,
      title: 'إرسال الطلبية للنورس؟',
      description: destination.isEmpty
          ? 'ستُنشأ شحنة لدى النورس لهذه الطلبية.'
          : 'ستُنشأ شحنة لدى النورس إلى $destination.',
      confirmLabel: 'إرسال',
    );

    if (!(confirmed ?? false) || !mounted) return;

    final result = await sl<LodgeOrder>()(order.id);

    if (!mounted) return;

    result.fold(
      // The server's own Arabic. This endpoint's refusals are written to be read by the person
      // who pressed the button — «الطلبية ١٢٣ استلام مكتب»، «مدينة ... غير مربوطة بنورس» — so a
      // sentence of ours on top of one of theirs would only bury it.
      (failure) => context.showFailure(failure),
      // Their code, because it is the one fact in the exchange nobody here can reconstruct: it
      // is what a colleague reads down the phone to Nawris.
      (parcel) => context.showSuccess(
        'أُرسلت للنورس — رقم الشحنة ${parcel.code}',
        details: 'الحالة تبقى «جاهزة» حتى يستلمها المندوب',
      ),
    );
  }

  /// Asks the carrier to deliver the same parcel again.
  ///
  /// **Not destructive, and not undoable either** — it puts goods back on a van. Asked plainly,
  /// and the answer names the new parcel's code, because a re-send makes a new one.
  Future<void> _resendShipment() => _releaseShipment(
    title: 'إعادة إرسال الشحنة؟',
    description: 'سيُطلب من النورس توصيلها مرة أخرى بنفس البيانات، وتُفتح شحنة جديدة برقم جديد.',
    confirmLabel: 'إعادة الإرسال',
    destructive: false,
    send: (id) => sl<ResendCarrierShipment>()(id),
    done: 'أُعيد إرسال الشحنة',
    nothing: 'لا توجد شحنة مفتوحة لهذه الطلبية',
  );

  /// Deletes the parcel at Nawris, freeing the order to be sent again.
  ///
  /// **Destructive at their end, so it is asked destructively.** Everything else this screen does
  /// is undone by doing it again; this one reaches into the carrier's system and removes a record
  /// only they can restore.
  Future<void> _deleteShipment() => _releaseShipment(
    title: 'حذف الشحنة من النورس؟',
    description: 'ستُحذف الشحنة لديهم وتتحرّر الطلبية لإرسالها من جديد.',
    confirmLabel: 'حذف',
    destructive: true,
    send: (id) => sl<DeleteCarrierShipment>()(id),
    done: 'حُذفت الشحنة من النورس',
    nothing: 'لا توجد شحنة مفتوحة لهذه الطلبية',
  );

  /// Drops our claim on a parcel without telling Nawris anything.
  Future<void> _unlinkShipment() => _releaseShipment(
    title: 'فكّ ربط الشحنة؟',
    description:
        'لن يُبلَّغ النورس بشيء — هذا للشحنة التي حُذفت من بوابتهم. تتحرّر الطلبية لإرسالها من جديد.',
    confirmLabel: 'فكّ الربط',
    destructive: false,
    send: (id) => sl<UnlinkCarrierShipment>()(id),
    done: 'فُكّ الربط — يمكن إرسالها من جديد',
    nothing: 'لا توجد شحنة مرتبطة بهذه الطلبية',
  );

  /// The shape both releases share: ask, send, say which of the two things happened.
  ///
  /// **A null parcel is an answer, not a failure.** The server says «لا توجد شحنة» rather than
  /// refusing, because pressing either of these twice is a person checking — so the success arm
  /// has two sentences and neither of them is red.
  Future<void> _releaseShipment({
    required String title,
    required String description,
    required String confirmLabel,
    required bool destructive,
    required Future<Either<Failure, NawrisParcel?>> Function(int orderId) send,
    required String done,
    required String nothing,
  }) async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final ask = destructive ? showDestructiveDialog : showCustomDialog;
    final confirmed = await ask(
      context: context,
      title: title,
      description: description,
      confirmLabel: confirmLabel,
    );

    if (!(confirmed ?? false) || !mounted) return;

    final result = await send(order.id);

    if (!mounted) return;

    result.fold(
      (failure) => context.showFailure(failure),
      (parcel) => parcel == null
          ? context.showSuccess(nothing)
          : context.showSuccess('$done — رقم الشحنة ${parcel.code}'),
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

  /// Puts an order back after a cancellation made by mistake.
  ///
  /// **The only status this screen writes**, and the exception to the rule at the top of the
  /// file that every move goes through «تغيير الحالة». That screen draws
  /// `available_transitions`, and «إلغاء تام» has none — nothing follows it on the server's map,
  /// which is exactly why the note above the button says so. This is not a move on the map; it
  /// is the undo of one recorded move, it offers no destination to choose and no fields to fill,
  /// so a whole screen for it would be a screen with one button on it.
  ///
  /// The confirmation lives in the dialog because there are two things to say before the tap and
  /// neither fits on a button: where the order lands, and that the stock does **not** come back
  /// off the shelf with it. The send happens here rather than in the dialog, for the reason
  /// every other form on this screen works that way — a form's answer is what was typed, and
  /// what to do about a refusal belongs to the screen that has somewhere to show it.
  ///
  /// Nothing is re-read afterwards: the response *is* the order, with its status, its timeline
  /// and — the one this screen cannot guess — a real `available_transitions` again.
  Future<void> _reinstate(BuildContext context) async {
    final cubit = context.read<OrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final draft = await showReinstateOrderDialog(context: context, order: order);
    if (draft == null || !mounted) return;

    final failure = await cubit.reinstate(reason: draft.reason);
    if (!mounted) return;

    if (failure != null) {
      // The server's own Arabic. «لا يوجد في سجل الطلبية الحالة التي أُلغيت منها» names what is
      // wrong and could not be written here without guessing at the timeline.
      context.showFailure(failure);

      return;
    }

    final updated = cubit.state.order;
    if (updated == null) return;

    context.showSuccess('رجعت الطلبية إلى «${updated.statusLabel}»');
    setState(() => _moved = updated);
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

  /// Opens the catalogue entry a line was sold from.
  ///
  /// Nothing is re-read on the way back: the order's lines are a snapshot taken when it was
  /// placed, and editing the product over there does not — must not — change what this invoice
  /// says. The picture and the code beside them are read fresh on the next load.
  void _openProduct(OrderItem item) {
    context.push(Routes.product(item.productId)).ignore();
  }

  /// Opens everything written on the order, each note beside the status it was written at.
  ///
  /// The order goes with it rather than its id alone: this screen already has it, and the page
  /// would otherwise fetch what is in hand. Nothing comes back — it only reads.
  void _openNotes() {
    final order = context.read<OrderDetailCubit>().state.order;
    if (order == null) return;

    context.push(Routes.orderNotes(order.id), extra: order).ignore();
  }

  /// Opens what has been done to this order — every field anybody changed, and when.
  ///
  /// **A record rather than an action**, which is why it sits in the header beside the notes and
  /// is no longer an arm of the dial: the dial moves the order, edits it and takes money, and
  /// this only ever opens something to read.
  void _openLog() {
    final order = context.read<OrderDetailCubit>().state.order;
    if (order == null) return;

    // Nothing comes back from a log and nothing is re-read afterwards: it is a screen that only
    // reads, so there is no result to wait for.
    context.push(Routes.activityLog(AuditSubject.order, order.id)).ignore();
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
    required this.onOpenProduct,
    required this.showCosts,
    required this.showOutsourcingCosts,
    required this.onScrap,
    required this.onOpenNotes,
    required this.onOpenLog,
    required this.onSendToCarrier,
    required this.onResendShipment,
    required this.onDeleteShipment,
    required this.onUnlinkShipment,
    required this.onReinstate,
  });

  final Order order;

  /// Null for anybody without `customers.view` — see [OrderCustomerCard].
  final Future<void> Function()? onOpenCustomer;

  /// Null for anybody without `products.view` — see [OrderItemCard].
  final void Function(OrderItem item)? onOpenProduct;

  /// Whether what the job cost us is drawn at all — see the call site for which grant answers
  /// this and why it is that one.
  final bool showCosts;

  /// Whether a وسيط line says what the vendor charges — `products.view_cost`.
  final bool showOutsourcingCosts;

  /// Null for anybody without `inventory.manage`.
  final Future<void> Function(BuildContext context, OrderItem item)? onScrap;

  /// Null on an order nobody wrote a note on.
  final VoidCallback? onOpenNotes;

  /// Null without `carrier.manage`. **The grant is only one of three conditions** — see
  /// [_maySendToCarrier] for the two the order itself answers.
  final Future<void> Function()? onSendToCarrier;

  /// Null without `carrier.manage` — and offered on a *returned* order, not on «جاهزة».
  final Future<void> Function()? onResendShipment;

  /// The two ways of taking a hand-over back. Same grant, same three conditions.
  final Future<void> Function()? onDeleteShipment;
  final Future<void> Function()? onUnlinkShipment;

  /// Null without `logs.view`.
  final VoidCallback? onOpenLog;

  /// Null unless the server said this order's cancellation may be undone — see the call site.
  final Future<void> Function(BuildContext context)? onReinstate;

  /// Whether spoiling a bag is even possible yet.
  ///
  /// **The warehouse is the condition, not the status.** An order whose stock has not left a
  /// shelf has nothing to draw a spoiled bag from, and the server refuses with «لم يُخصَم مخزونها
  /// بعد» — a refusal worth never reaching, because the action would be offered on every order in
  /// the shop to no purpose. Reading the warehouse rather than the status is also what let the
  /// deduction move from «قيد الطباعة» to «جاهزة» without touching this line.
  bool get _mayScrap => onScrap != null && order.fulfillmentWarehouseId != null;

  /// Whether this order can be handed to Nawris at all.
  ///
  /// **«جاهزة» and a delivery, and both for the same reason: the bags exist and they are
  /// going somewhere.** An order still in production has nothing for a courier to carry, and an
  /// «استلام مكتب» never leaves the building — the server refuses both by name, and this only
  /// decides whether to offer a button that would earn one of those refusals.
  ///
  /// **«إعادة إرسال» is deliberately not offered here** even though the server accepts it: a
  /// returned order goes out again through the status screen, and a second door onto the same
  /// act is a second thing to keep in step. The retry after a failed hand-over is the
  /// not-lodged queue's job, which is a screen this app does not have yet.
  bool get _maySendToCarrier =>
      onSendToCarrier != null &&
      order.status == OrderStatus.ready &&
      !order.isOfficePickup;

  /// Either moment: goods about to go, or goods that came back.
  bool get _mayTouchTheCarrier => _maySendToCarrier || _mayResendToCarrier;

  /// Whether this order is one the carrier could be asked to deliver again.
  ///
  /// **The mirror of [_maySendToCarrier], and never true at the same time.** Sending is for goods
  /// that have not left; re-sending is for goods that came back and are going out once more. The
  /// four return statuses are exactly the window in which that request means anything — before
  /// them nothing has come back, and «تم الاستلام» is the end.
  ///
  /// Whether the parcel is *still open* at their end is the server's question, not this one's: it
  /// answers «لا توجد شحنة مفتوحة» when the return chain has already closed it.
  bool get _mayResendToCarrier =>
      onResendShipment != null &&
      !order.isOfficePickup &&
      const {
        OrderStatus.returnedCourier,
        OrderStatus.returnedCarrier,
        OrderStatus.returnedOffice,
        OrderStatus.resend,
      }.contains(order.status);

  /// Whether the delivery section has anything left to say.
  ///
  /// **The city and the region are the header's now**, and the note has a button of its own, so
  /// an office pickup with nothing else recorded would draw an empty card with a title on it.
  bool get _hasDestinationDetails =>
      order.customerShopName != null ||
      order.addressDetails != null ||
      order.recipientName != null ||
      order.recipientPhone != null ||
      order.trackingNumber != null ||
      order.nawrisParcel != null ||
      order.shippingCompany != null;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // Scrollable even when short, so pull-to-refresh works on every state.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        OrderDetailHeader(
          order: order,
          onOpenNotes: onOpenNotes,
          onOpenLog: onOpenLog,
          onSendToCarrier: _maySendToCarrier ? onSendToCarrier : null,
          onResendShipment: _mayResendToCarrier ? onResendShipment : null,
          // Offered wherever either of the two above is: whichever moment the order is in, a
          // hand-over may need taking back.
          onDeleteShipment: _mayTouchTheCarrier ? onDeleteShipment : null,
          onUnlinkShipment: _mayTouchTheCarrier ? onUnlinkShipment : null,
        ),
        SliverPadding(
          // Deep bottom padding: the floating dial hangs over this list, and a total it covers
          // is a number somebody has to move the screen to read.
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
          sliver: SliverList.list(
            children: [
              // First under the header, and that is the sequence rather than a spare slot:
              // somebody who has just read what state the order is in is one step from telling
              // the customer so. Buried on the dial it was a feature people forgot the app had.
              CopyInvoiceButton(order: order),
              SizedBox(height: 16.h),
              _Header(order: order),
              SizedBox(height: 16.h),
              // Who it is for, and the way to them. The header names them; this is where the
              // number is rung and the door into their file is.
              OrderCustomerCard(order: order, onTap: onOpenCustomer),
              // Moving the order lives on the floating button. Silence is not an explanation, so
              // an order that can go nowhere still says which of the two reasons applies: the
              // dial is simply not rendered, and a finished order and a user without the grant
              // look identical otherwise.
              if (!order.hasActions) ...[
                SizedBox(height: 16.h),
                _Note(
                  // **A cancellation that may be undone is not «لا مزيد من الإجراءات».** The
                  // sentence under it is about to be followed by a button, and a note claiming
                  // the road ends here would be arguing with it.
                  text: order.canReinstate
                      ? 'الطلبية ${order.statusLabel} — والإلغاء وحده ما يمكن التراجع عنه'
                      : order.isFinal
                      ? 'الطلبية ${order.statusLabel} — لا مزيد من الإجراءات'
                      : 'لا تملك صلاحية تغيير حالة هذه الطلبية',
                ),
                // **The one action that is not on the dial, and it belongs here rather than
                // there.** The dial draws `available_transitions`, and «إلغاء تام» has none —
                // that is what the note above says. Undoing the cancellation is the answer to
                // exactly the sentence somebody has just read, so it stands under it.
                if (onReinstate case final reinstate?) ...[
                  SizedBox(height: 12.h),
                  AppButton.tonal(
                    // Named with its destination, because the undo offers no choice of one: the
                    // server puts the order back where it was cancelled from, and saying so on
                    // the button beats saying so only after the tap.
                    label: switch (order.reinstateToLabel) {
                      final to? when to.isNotEmpty => 'تراجع عن الإلغاء — ترجع إلى «$to»',
                      _ => 'تراجع عن الإلغاء',
                    },
                    icon: AppIcons.undo,
                    onPressed: () => reinstate(context),
                  ),
                ],
              ],
              if (_hasDestinationDetails) ...[
                SizedBox(height: 16.h),
                _Destination(order: order),
              ],
              if (order.items != null && order.items!.isNotEmpty) ...[
                SizedBox(height: 16.h),
                _Section(
                  title: 'البنود',
                  child: _Items(
                    items: order.items!,
                    // The lines' own sum, under the lines — see [_Items].
                    weight: order.weightLabel,
                    showCosts: showCosts,
                    showOutsourcingCosts: showOutsourcingCosts,
                    onScrap: _mayScrap ? onScrap : null,
                    onOpenProduct: onOpenProduct,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              // **Read here, changed on «تعديل الطلبية».** Every figure in this column is one
              // the edit screen writes — the lines, the discount, the added charge — and a
              // second door onto any of them would be a second place to keep right.
              // **The added charge is one of its lines and is named there.** It had a section of
              // its own under this one, which printed the same figure a card away from the
              // column it belongs to — one charge, answered twice. What that section carried and
              // the account did not is *what for*, and that sentence now sits under the line
              // itself; «تعديل الطلبية» is still where it is argued with.
              _Section(title: 'الحساب', child: OrderTotals(order: order)),
              // **Under «الحساب», never inside it.** What the customer pays is the question this
              // screen is opened to answer; what the job cost us is the quieter one asked
              // afterwards, by fewer people — see the grant at the call site — and mixing the two
              // columns would put a figure nobody reads out to a customer in the middle of the
              // ones they do.
              if (showCosts) ...[
                SizedBox(height: 16.h),
                _Section(title: 'التكلفة والربح', child: OrderCostSection(order: order)),
              ],
              // Shown even when no version exists yet, because that is exactly the order somebody
              // opens this screen to add one to. Any order may carry artwork — `design_source`
              // says whose work it was, which is a question about money, not about whether there
              // is a file.
              if (order.designs != null) ...[
                SizedBox(height: 16.h),
                _Section(
                  title: 'التصاميم',
                  // Read here, changed on «تعديل الطلبية». Adding a version and judging one are
                  // both edits, and this screen having its own copies of them would be a second
                  // door onto the same room.
                  child: OrderDesignsSection(designs: order.designs!),
                ),
              ],
              if (order.transitions != null && order.transitions!.isNotEmpty) ...[
                SizedBox(height: 16.h),
                _Section(title: 'سجل الحالات', child: OrderTimeline(records: order.transitions!)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The two states that have no order yet, under a bar of their own.
///
/// [OrderDetailHeader] draws the order — its number, its customer, its state — so there is
/// nothing for it to draw while the request is still out or after it failed. A plain bar keeps
/// «رجوع» where the thumb expects it in the meantime.
class _BeforeTheOrder extends StatelessWidget {
  const _BeforeTheOrder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // `always`, so pull-to-refresh reaches a failure that fills the screen.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverAppBar(title: Text('تفاصيل الطلبية')),
        SliverFillRemaining(hasScrollBody: false, child: child),
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
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
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
          // The delivery fee the customer handed the courier at the door.
          //
          // **A sentence rather than a fourth figure**, for the reason the write-off line is
          // one: three money cells already share a narrow row. And **deliberately not added to
          // «المدفوع»** — that number means cash we hold, and this never reached the drawer.
          // Without the line, though, the row above is arithmetic that does not add up: an
          // order of 120 showing 100 paid and nothing outstanding reads as a bug.
          if (order.carrierSettledAmount != '0.00') ...[
            SizedBox(height: 10.h),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'سُدِّدت لدى الناقل ${order.carrierSettledAmount.grouped} — لم تصل الصندوق',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
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

        // «التكلفة الإضافية» used to stand here. It is a button inside «الحساب» now, beside
        // the line it changes — the dial acts on the *order*, and this argues with one figure
        // on its invoice. Same reasoning as «تسجيل تلف» living on the line it spoils.

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

        // «سجل التعديلات» used to stand here. It reads and never writes, which is what the two
        // buttons in the header are for — see [OrderDetailHeader] — and an action on the dial
        // that only opens a page to look at was the odd one out among five that change things.
      ],
    );
  }
}

/// The rest of where it goes — everything the header's one line does not carry.
///
/// **The city and the region are not repeated here.** «عنوان توصيل: طرابلس — الحشان» is at the
/// top of the screen; this section is the branch, the street, who signs for it and which carrier
/// has it. Nor is the note, which has its own button up there — a paragraph between the address
/// and the tracking number was read by nobody and scrolled past by everybody.
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
          // Beside «رقم التتبع» and never merged with it: that one is typed by a person, this
          // one is what the carrier called the parcel. An order can carry both, and they differ.
          if (order.nawrisParcel case final parcel?)
            _Row(icon: AppIcons.tag, label: 'كود النورس', value: parcel.code),
          if (order.shippingCompany case final company?)
            _Row(icon: AppIcons.warehouse, label: 'شركة الشحن', value: company),
        ],
      ),
    );
  }
}

/// The lines, and what they weigh together.
///
/// **The weight belongs here and nowhere else on the screen.** It is not a fact about the order
/// the way its number or its customer is — it is the sum of what the warehouse recorded against
/// these lines, and the order itself stopped carrying a weight of its own when `weight_kg` was
/// dropped. Under «الحساب» it would sit among the money and read as another figure on the
/// invoice; in the header it would claim to be true of orders that have never been near a scale.
class _Items extends StatelessWidget {
  const _Items({
    required this.items,
    required this.weight,
    required this.showCosts,
    required this.showOutsourcingCosts,
    required this.onScrap,
    required this.onOpenProduct,
  });

  final List<OrderItem> items;

  /// «12.5 كيلوغرام», or null on an order with no weight to state — see [Order.totalWeight],
  /// where null covers both «nothing here is weighed» and «nothing has been weighed yet». The
  /// server decides which; the screen only draws the line when there is one.
  final String? weight;

  /// Whether each line says what it cost to make, under what it is charged at.
  final bool showCosts;

  /// Whether a وسيط line says what the vendor charges — see [OrderLineCosts].
  final bool showOutsourcingCosts;

  /// Null when scrapping is not on offer — no grant, or an order with no shelf behind it yet.
  final Future<void> Function(BuildContext context, OrderItem item)? onScrap;

  /// Null for anybody without `products.view` — see [OrderItemCard].
  final void Function(OrderItem item)? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) SizedBox(height: 10.h),
          OrderItemCard(
            item: item,
            showCosts: showCosts,
            showOutsourcingCosts: showOutsourcingCosts,
            // Only for a line whose product came with the payload: a card with nothing to open
            // is the arrow onto a 403 in another costume.
            onOpenProduct: onOpenProduct == null ? null : () => onOpenProduct!(item),
            onScrap: onScrap == null ? null : () => onScrap!(context, item).ignore(),
          ),
        ],
        if (weight case final label?) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(height: 1, color: context.colorScheme.outlineVariant),
          ),
          Row(
            children: [
              Text(
                'وزن الطلبية',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // No `textDirection` override: «12.5 كيلوغرام» is a number *and* an Arabic word,
              // and forcing the run left-to-right would put the unit on the wrong side of it.
              // The overrides elsewhere on this screen are for bare figures.
              Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
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
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
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
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
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
