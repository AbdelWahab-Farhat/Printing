import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter/foundation.dart';

/// «تسوية الدفعات» — the payments whose money is still where it landed, and those already carried
/// on, across every order. TREASURY-DESIGN §٢٣.
///
/// Narrowed by the period chips (اليوم · هذا الأسبوع · هذا الشهر · الكل · من – إلى), by where the
/// money waits, and by an order code or a customer's name — all on the server, with the total
/// ([amountTotal]) the server adds up over everything that matched, not over the page loaded.
///
/// **Re-read, never patched, after a settlement or an undo**: either moves rows between the two
/// lists and changes the total, and the total is the server's answer.
class PaymentSettlementCubit extends PagedCubit<OrderPayment> {
  PaymentSettlementCubit({
    required GetPaymentSettlementQueue getQueue,
    required GetSettlementAccounts getAccounts,
    required SettleOrderPayments settlePayments,
    required UnsettleOrderPayment unsettlePayment,
    this.tab = SettlementState.pending,
    DateTime Function()? now,
  }) : _getQueue = getQueue,
       _getAccounts = getAccounts,
       _settlePayments = settlePayments,
       _unsettlePayment = unsettlePayment,
       _now = now ?? DateTime.now;

  final GetPaymentSettlementQueue _getQueue;
  final GetSettlementAccounts _getAccounts;
  final SettleOrderPayments _settlePayments;
  final UnsettleOrderPayment _unsettlePayment;
  final DateTime Function() _now;

  /// Which list this is. Fixed for the Cubit's life: each tab of the page owns one, so swiping
  /// between them keeps each list's filters, search and scroll — the inventory tab's shape.
  final SettlementState tab;

  /// «الكل» to begin with: it is a work list, and a payment left from last month is the one most
  /// worth finding.
  SettlementPeriod period = SettlementPeriod.all;

  /// The two days of «من – إلى», when [period] is it.
  ({DateTime from, DateTime to})? customRange;

  /// Where the money waits — Nawris, «مصرف علي» — or null for every account.
  int? accountId;

  /// Where payments wait and where they may go. Null until the server has answered; a failure
  /// leaves it null and the page offers no account chips rather than wrong ones.
  final ValueNotifier<SettlementAccounts?> accounts = ValueNotifier<SettlementAccounts?>(null);

  /// What the whole filtered list adds up to, as the server said it.
  String get amountTotal => switch (state) {
    PagedLoaded(:final page) => '${page.extraMeta['amount_total'] ?? '0.00'}',
    _ => '0.00',
  };

  /// How many payments the whole filtered list holds. Null before the server has answered.
  int? get count => switch (state) {
    PagedLoaded(:final page) => page.meta.total,
    _ => null,
  };

  /// The first and last day shown, or null for «الكل».
  ({DateTime from, DateTime to})? get range => switch (period) {
    SettlementPeriod.custom => customRange,
    _ => period.rangeAt(_now()),
  };

  /// The list, and the accounts beside it.
  Future<void> start() async {
    await Future.wait([load(), loadAccounts()]);
  }

  Future<void> loadAccounts() async {
    final result = await _getAccounts();

    if (isClosed) return;

    result.fold((_) {}, (value) => accounts.value = value);
  }

  /// [between] for «من – إلى» alone; a new pair re-reads even while the period stays «من – إلى».
  ///
  /// **What is typed in the search box stays** across every filter change: changing the period
  /// does not erase what somebody wrote to find.
  Future<void> showPeriod(SettlementPeriod value, {({DateTime from, DateTime to})? between}) {
    if (value == period && between == null) return Future<void>.value();

    period = value;
    customRange = value == SettlementPeriod.custom ? between : null;

    return load(search: currentSearch);
  }

  Future<void> showAccount(int? value) {
    if (value == accountId) return Future<void>.value();

    accountId = value;

    return load(search: currentSearch);
  }

  /// Settles [rows] — all or nothing — and re-reads. Answers with the failure for the sheet to
  /// show beside the row the server named.
  Future<Failure?> settle(List<SettleRow> rows, {int? accountId}) async {
    final result = await _settlePayments(rows, accountId: accountId);

    return result.fold((failure) => failure, (_) async {
      await refresh();

      return null;
    });
  }

  /// Takes [payment]'s settlement back and re-reads.
  Future<Failure?> unsettle(OrderPayment payment, {required String reason}) async {
    final result = await _unsettlePayment(payment.orderId, payment.id, reason: reason);

    return result.fold((failure) => failure, (_) async {
      await refresh();

      return null;
    });
  }

  @override
  Object identityOf(OrderPayment item) => item.id;

  @override
  Future<Either<Failure, Paginated<OrderPayment>>> fetchPage({
    String? search,
    required int page,
  }) {
    final shown = range;

    return _getQueue(
      page: page,
      state: tab,
      from: shown?.from,
      to: shown?.to,
      accountId: accountId,
      search: search,
    );
  }

  @override
  Future<void> close() {
    accounts.dispose();

    return super.close();
  }
}

typedef PaymentSettlementState = PagedState<OrderPayment>;
