import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «إعدادات المالية» — the switches, the default account of each method, where each custody
/// settles into, and the accounts. TREASURY-DESIGN §١٦. التصنيفاتُ صارت شاشةً وحدها.
///
/// **Every change is saved as it is made** and the page reloads from the server: there is no
/// «حفظ» button to forget, and what is drawn is always what the server holds.
class TreasurySettingsCubit extends Cubit<TreasurySettingsState> {
  TreasurySettingsCubit({
    required GetTreasurySettings getSettings,
    required SaveTreasurySettings saveSettings,
    required GetTreasuryAccounts getAccounts,
    required SaveTreasuryAccount saveAccount,
    required SetSettlesInto setSettlesInto,
  }) : _getSettings = getSettings,
       _saveSettings = saveSettings,
       _getAccounts = getAccounts,
       _saveAccount = saveAccount,
       _setSettlesInto = setSettlesInto,
       super(const TreasurySettingsLoading());

  final GetTreasurySettings _getSettings;
  final SaveTreasurySettings _saveSettings;
  final GetTreasuryAccounts _getAccounts;
  final SaveTreasuryAccount _saveAccount;
  final SetSettlesInto _setSettlesInto;

  Future<void> load() async {
    final (settings, accounts) = await (_getSettings(), _getAccounts()).wait;

    if (isClosed) return;

    final failure = [
      settings.fold((f) => f, (_) => null),
      accounts.fold((f) => f, (_) => null),
    ].nonNulls.firstOrNull;

    if (failure != null) {
      emit(TreasurySettingsFailed(failure));

      return;
    }

    emit(
      TreasurySettingsLoaded(
        settings: settings.getOrElse(() => throw StateError('checked above')),
        accounts: accounts.getOrElse(() => throw StateError('checked above')).accounts,
      ),
    );
  }

  /// Runs one write, reloads the page on success, and hands back the failure for a toast.
  Future<Failure?> _after<T>(Future<Either<Failure, T>> Function() write) async {
    final result = await write();
    final failure = result.fold<Failure?>((f) => f, (_) => null);

    if (failure == null && !isClosed) unawaited(load());

    return failure;
  }

  Future<Failure?> saveSettings({
    bool? ownAccountFirst,
    bool? blockOverdraft,
    bool? withdrawalNeedsReason,
    bool? askCarrierFee,
    String? lockedUntil,
    bool clearLock = false,
  }) => _after(
    () => _saveSettings(
      ownAccountFirst: ownAccountFirst,
      blockOverdraft: blockOverdraft,
      withdrawalNeedsReason: withdrawalNeedsReason,
      askCarrierFee: askCarrierFee,
      lockedUntil: lockedUntil,
      clearLock: clearLock,
    ),
  );

  /// Makes [account] the default of its kind; the old default loses the title on the server.
  Future<Failure?> makeDefault(TreasuryAccount account) =>
      _after(() => _saveAccount(id: account.id, name: account.name, isDefault: true));

  Future<Failure?> setSettlesInto(TreasuryAccount custody, int? targetId) =>
      _after(() => _setSettlesInto(custody: custody, targetId: targetId));

  /// «التجميع عند التسوية» for [kind]: [on] switches it, [intoId] names the account — or,
  /// with [toDefault], goes back to the kind's default. TREASURY-DESIGN §١٨.
  Future<Failure?> saveCollection(
    AccountKind kind, {
    bool? on,
    int? intoId,
    bool toDefault = false,
  }) => _after(
    () => _saveSettings(
      collectKind: kind,
      collectOn: on,
      collectIntoId: intoId,
      clearCollectInto: toDefault,
    ),
  );

  /// Links [box] to [office] — the server unlinks whichever box served it before — or, with a
  /// null [box], unlinks the one that does, so its cash follows the usual rules again (§١٩).
  Future<Failure?> setPickupOfficeBox(
    PickupOffice office,
    TreasuryAccount? box,
    List<TreasuryAccount> accounts,
  ) {
    if (box != null) {
      return _after(() => _saveAccount(id: box.id, name: box.name, pickupCityId: office.cityId));
    }

    final current = accounts.where((a) => a.id == office.accountId).firstOrNull;

    if (current == null) return Future.value();

    return _after(() => _saveAccount(id: current.id, name: current.name, clearPickupCity: true));
  }

  /// «يُجمَع عند التسوية» on one account — off keeps its order money where it landed.
  Future<Failure?> setCollected(TreasuryAccount account, bool collected) =>
      _after(() => _saveAccount(id: account.id, name: account.name, isCollected: collected));

  Future<Failure?> saveAccount({
    int? id,
    required String name,
    String? kind,
    bool? isDefault,
    bool? isActive,
    int? holderUserId,
    String? notes,
  }) => _after(
    () => _saveAccount(
      id: id,
      name: name,
      kind: kind,
      isDefault: isDefault,
      isActive: isActive,
      holderUserId: holderUserId,
      notes: notes,
    ),
  );

}

sealed class TreasurySettingsState {
  const TreasurySettingsState();
}

final class TreasurySettingsLoading extends TreasurySettingsState {
  const TreasurySettingsLoading();
}

final class TreasurySettingsFailed extends TreasurySettingsState {
  const TreasurySettingsFailed(this.failure);

  final Failure failure;
}

final class TreasurySettingsLoaded extends TreasurySettingsState {
  const TreasurySettingsLoaded({required this.settings, required this.accounts});

  final TreasurySettings settings;
  final List<TreasuryAccount> accounts;
}
