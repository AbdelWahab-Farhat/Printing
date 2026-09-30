import 'dart:async';

import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The treasury dashboard: every account with its balance, whose the money is, and what the
/// shelves are worth — TREASURY-DESIGN §٩.
///
/// **The two cards are asked for only when the reader may see the whole treasury.** Somebody
/// reading the accounts in their own name gets their own balance and nothing about the shop's.
/// And a card that fails to load leaves the accounts standing: they are the screen, the cards
/// are what sits under it.
class TreasuryCubit extends Cubit<TreasuryState> {
  TreasuryCubit({
    required GetTreasuryAccounts getAccounts,
    required GetTreasuryOwnership getOwnership,
    required GetInventoryValue getInventoryValue,
    required RecordTreasuryOperation recordOperation,
    required SaveTreasuryAccount saveAccount,
  }) : _getAccounts = getAccounts,
       _getOwnership = getOwnership,
       _getInventoryValue = getInventoryValue,
       _recordOperation = recordOperation,
       _saveAccount = saveAccount,
       super(const TreasuryLoading());

  final GetTreasuryAccounts _getAccounts;
  final GetTreasuryOwnership _getOwnership;
  final GetInventoryValue _getInventoryValue;
  final RecordTreasuryOperation _recordOperation;
  final SaveTreasuryAccount _saveAccount;

  Future<void> load() async {
    if (state is! TreasuryLoaded) emit(const TreasuryLoading());

    final result = await _getAccounts();

    if (isClosed) return;

    await result.fold((failure) async => emit(TreasuryFailed(failure)), (accounts) async {
      emit(TreasuryLoaded(accounts: accounts));

      if (!accounts.canViewAll) return;

      final (ownership, inventory) = await (_getOwnership(), _getInventoryValue()).wait;

      if (isClosed || state is! TreasuryLoaded) return;

      emit(
        TreasuryLoaded(
          accounts: accounts,
          ownership: ownership.fold((_) => null, (value) => value),
          inventory: inventory.fold((_) => null, (value) => value),
        ),
      );
    });
  }

  /// One hand operation from the dashboard. Null on success, the failure otherwise — the form
  /// shows it and stays open.
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

  Future<Failure?> saveAccount({
    int? id,
    required String name,
    String? kind,
    bool? isDefault,
    bool? isActive,
    int? holderUserId,
    String? notes,
  }) async {
    final result = await _saveAccount(
      id: id,
      name: name,
      kind: kind,
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

sealed class TreasuryState {
  const TreasuryState();
}

final class TreasuryLoading extends TreasuryState {
  const TreasuryLoading();
}

final class TreasuryFailed extends TreasuryState {
  const TreasuryFailed(this.failure);

  final Failure failure;
}

final class TreasuryLoaded extends TreasuryState {
  const TreasuryLoaded({required this.accounts, this.ownership, this.inventory});

  final TreasuryAccounts accounts;

  /// Null until it arrives, or when it failed — the card is simply not drawn.
  final TreasuryOwnership? ownership;
  final InventoryValue? inventory;
}
