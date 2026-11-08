import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_period_filter.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter/foundation.dart';

/// «تسوية الدفعات» — the payments whose money is still where it landed, and those already carried
/// on, across every order. TREASURY-DESIGN §٢٣.
///
/// Narrowed on the server by the period chips on «الكل» ([PaymentPeriodFilter]), by an order code
/// or a customer's name, and — in the advanced filter — by «من» / «إلى», where the money waits
/// (2026-10-08), and the rest of [PaymentPeriodFilter.detail] (2026-11-07).
///
/// **Re-read, never patched, after a settlement or an undo**: either moves rows between the two
/// lists and changes the count, and the count is the server's answer.
class PaymentSettlementCubit extends PagedCubit<OrderPayment> with PaymentPeriodFilter {
  PaymentSettlementCubit({
    required GetPaymentSettlementQueue getQueue,
    required GetPaymentFilterOptions getOptions,
    required GetSettlementAccounts getAccounts,
    required SettleOrderPayments settlePayments,
    required UnsettleOrderPayment unsettlePayment,
    this.tab = SettlementState.pending,
    DateTime Function()? now,
  }) : _getQueue = getQueue,
       _getOptions = getOptions,
       _getAccounts = getAccounts,
       _settlePayments = settlePayments,
       _unsettlePayment = unsettlePayment,
       _now = now ?? DateTime.now;

  final GetPaymentSettlementQueue _getQueue;
  final GetPaymentFilterOptions _getOptions;
  final GetSettlementAccounts _getAccounts;
  final SettleOrderPayments _settlePayments;
  final UnsettleOrderPayment _unsettlePayment;
  final DateTime Function() _now;

  /// Which list this is. Fixed for the Cubit's life: «بانتظار التسوية» and «مسوّاة» each own one,
  /// so switching between them keeps each list's filters, search and scroll.
  final SettlementState tab;

  @override
  DateTime clock() => _now();

  @override
  Future<Either<Failure, PaymentFilterOptions>> fetchFilterOptions() => _getOptions();

  /// Where the money waits — Nawris, «مصرف علي» — or null for every account. Set from the
  /// advanced filter.
  int? accountId;

  /// Whether the advanced filter narrows the list — what lights its button.
  bool get hasAdvanced =>
      period == SettlementPeriod.custom || accountId != null || !detail.isEmpty;

  /// Where payments wait and where they may go. Null until the server has answered; a failure
  /// leaves it null, and settling asks again.
  final ValueNotifier<SettlementAccounts?> accounts = ValueNotifier<SettlementAccounts?>(null);

  /// How many payments the whole filtered list holds — what the tab says beside its name. Null
  /// before the server has answered.
  int? get count => switch (state) {
    PagedLoaded(:final page) => page.meta.total,
    _ => null,
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

  /// «تطبيق» in the advanced filter: everything in it, in one load.
  ///
  /// **What is typed in the search box stays** across every filter change: changing the period
  /// does not erase what somebody wrote to find.
  Future<void> applyAdvanced({
    DateTime? from,
    DateTime? to,
    int? accountId,
    PaymentDetailFilter detail = const PaymentDetailFilter(),
  }) {
    adoptDates(from: from, to: to);
    this.accountId = accountId;
    this.detail = detail;

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
      detail: detail,
    );
  }

  @override
  Future<void> close() {
    accounts.dispose();

    return super.close();
  }
}

typedef PaymentSettlementState = PagedState<OrderPayment>;
