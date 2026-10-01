import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The top of an account's page: its balance and its figures by kind.
///
/// Its own cubit beside [AccountMovementsCubit] rather than folded into it: the history pages,
/// the header does not, and an operation recorded from this page refreshes both.
class TreasuryAccountCubit extends Cubit<TreasuryAccountState> {
  TreasuryAccountCubit({
    required this.accountId,
    required GetTreasuryAccount getAccount,
    required RecordTreasuryOperation recordOperation,
    required ReverseTreasuryOperation reverseOperation,
    required SaveTreasuryAccount saveAccount,
  }) : _getAccount = getAccount,
       _recordOperation = recordOperation,
       _reverseOperation = reverseOperation,
       _saveAccount = saveAccount,
       super(const TreasuryAccountLoading());

  final int accountId;
  final GetTreasuryAccount _getAccount;
  final RecordTreasuryOperation _recordOperation;
  final ReverseTreasuryOperation _reverseOperation;
  final SaveTreasuryAccount _saveAccount;

  Future<void> load() async {
    final result = await _getAccount(accountId);

    if (isClosed) return;

    emit(result.fold(TreasuryAccountFailed.new, TreasuryAccountLoaded.new));
  }

  Future<Failure?> record({
    required OperationKind kind,
    String? amount,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    int? employeeId,
    String? countedBalance,
    String? notes,
  }) async {
    final result = await _recordOperation(
      kind: kind,
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      employeeId: employeeId,
      countedBalance: countedBalance,
      notes: notes,
    );

    return result.fold((failure) => failure, (_) {
      unawaited(load());

      return null;
    });
  }

  Future<Failure?> reverse(int operationId, {required String reason}) async {
    final result = await _reverseOperation(operationId, reason: reason);

    return result.fold((failure) => failure, (_) {
      unawaited(load());

      return null;
    });
  }

  Future<Failure?> save({
    required String name,
    String? kind,
    bool? isDefault,
    bool? isActive,
    int? holderUserId,
    String? notes,
  }) async {
    final result = await _saveAccount(
      id: accountId,
      name: name,
      isDefault: isDefault,
      isActive: isActive,
      holderUserId: holderUserId,
      notes: notes,
    );

    return result.fold((failure) => failure, (_) {
      unawaited(load());

      return null;
    });
  }
}

sealed class TreasuryAccountState {
  const TreasuryAccountState();
}

final class TreasuryAccountLoading extends TreasuryAccountState {
  const TreasuryAccountLoading();
}

final class TreasuryAccountFailed extends TreasuryAccountState {
  const TreasuryAccountFailed(this.failure);

  final Failure failure;
}

final class TreasuryAccountLoaded extends TreasuryAccountState {
  const TreasuryAccountLoaded(this.detail);

  final TreasuryAccountDetail detail;
}

/// An account's history, newest first. Read-only: every line is the trace of something done
/// elsewhere — a payment, a transfer, a count.
class AccountMovementsCubit extends PagedCubit<TreasuryMovement> {
  AccountMovementsCubit({required this.accountId, required GetAccountMovements getMovements})
    : _getMovements = getMovements;

  final int accountId;
  final GetAccountMovements _getMovements;

  @override
  Object identityOf(TreasuryMovement item) => item.id;

  @override
  Future<Either<Failure, Paginated<TreasuryMovement>>> fetchPage({
    String? search,
    required int page,
  }) => _getMovements(accountId, page: page);
}

typedef AccountMovementsState = PagedState<TreasuryMovement>;
