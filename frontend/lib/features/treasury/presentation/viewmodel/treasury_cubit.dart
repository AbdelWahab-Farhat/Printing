import 'dart:async';

import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/account_change.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// لوحة الحسابات: كل حسابٍ برصيده، ولمن المال، وما تساويه الرفوف — TREASURY-DESIGN §٩.
///
/// **البطاقتان لا تُطلبان إلا لمن يرى الخزينة كلها.** من يقرأ الحسابات التي باسمه يرى رصيده
/// ولا شيء عن مال المحل. وبطاقةٌ تفشل لا تُسقط الحسابات: الحسابات هي الشاشة، والبطاقتان تحتها.
///
/// **إعادة التحميل لا تمحو ما على الشاشة.** فشلُها يُبقي آخر ما قُرئ ويحمل الفشل في
/// [TreasuryLoaded.refreshFailure] ليقوله توست، والبطاقتان تبقيان في مكانهما حتى يصل جديدهما.
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

  /// عدّادٌ يحمي من الرد المتأخر: تحميلٌ بدأ قبل آخرَ لا يكتب فوق جوابه — RULES §٤.
  int _requestId = 0;

  Future<void> load() async {
    final requestId = ++_requestId;
    final previous = switch (state) {
      final TreasuryLoaded loaded => loaded,
      _ => null,
    };

    // الدائرة لمن لا شيء على شاشته — وأولُ تحميلٍ يبدأ عليها أصلاً.
    if (state is TreasuryFailed) emit(const TreasuryLoading());

    final result = await _getAccounts();

    if (isClosed || requestId != _requestId) return;

    final accounts = result.fold<TreasuryAccounts?>((failure) {
      emit(previous == null ? TreasuryFailed(failure) : previous.failedRefresh(failure));

      return null;
    }, (accounts) => accounts);

    if (accounts == null) return;

    // من فقد صلاحية الكل منذ آخر قراءة لا يبقى أمامه رقمٌ عن مال المحل.
    final ownership = accounts.canViewAll ? previous?.ownership : null;
    final inventory = accounts.canViewAll ? previous?.inventory : null;

    emit(TreasuryLoaded(accounts: accounts, ownership: ownership, inventory: inventory));

    if (!accounts.canViewAll) return;

    final (owners, shelves) = await (_getOwnership(), _getInventoryValue()).wait;

    if (isClosed || requestId != _requestId) return;

    emit(
      TreasuryLoaded(
        accounts: accounts,
        // بطاقةٌ فشلت تُبقي آخر ما قالته — وفي أول تحميلٍ لا تُرسم.
        ownership: owners.fold((_) => ownership, (value) => value),
        inventory: shelves.fold((_) => inventory, (value) => value),
      ),
    );
  }

  /// عمليةٌ يدوية من اللوحة. null عند النجاح، والرفضُ غير ذلك — النموذج يعرضه ويبقى مفتوحاً.
  ///
  /// **النجاح يعيد قراءة اللوحة**: المجموع ورصيد الطرف الآخر في التحويل و«مال الشركة» حساباتُ
  /// الخادم، لا يرقّعها التطبيق.
  Future<Failure?> record({
    required OperationKind kind,
    String? amount,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    int? employeeId,
    String? countedBalance,
    String? notes,
    String? clientToken,
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
      clientToken: clientToken,
    );

    return result.fold((failure) => failure, (_) {
      if (!isClosed) unawaited(load());

      return null;
    });
  }

  /// حسابٌ جديد من اللوحة. **يعيد القراءة** لأن مكانه في القائمة ترتيبُ الخادم (النوع، ثم
  /// الافتراضي، ثم الاسم) لا يخترعه التطبيق.
  Future<Failure?> saveAccount({
    required String name,
    String? kind,
    bool? isDefault,
    int? holderUserId,
    String? notes,
  }) async {
    final result = await _saveAccount(
      name: name,
      kind: kind,
      isDefault: isDefault,
      holderUserId: holderUserId,
      notes: notes,
    );

    return result.fold((failure) => failure, (_) {
      if (!isClosed) unawaited(load());

      return null;
    });
  }

  /// ما أعادته صفحة الحساب: التعديل يُرقَّع في مكانه، والمال الذي تحرّك يُقرأ من جديد.
  Future<void> applyAccountChange(AccountChange change) async {
    switch (change) {
      case AccountEdited(:final account):
        if (state case final TreasuryLoaded loaded) {
          emit(
            loaded.withAccounts(
              loaded.accounts.withAccounts(withSavedAccount(loaded.accounts.accounts, account)),
            ),
          );
        }
      case AccountMoneyMoved():
        await load();
    }
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
  const TreasuryLoaded({
    required this.accounts,
    this.ownership,
    this.inventory,
    this.refreshFailure,
  });

  final TreasuryAccounts accounts;

  /// فارغةٌ حتى تصل، أو حين فشلت في أول تحميل — فلا تُرسم البطاقة.
  final TreasuryOwnership? ownership;
  final InventoryValue? inventory;

  /// إعادةُ تحميلٍ فشلت والشاشة باقية على ما قبلها: يقوله توستٌ مرةً واحدة.
  final Failure? refreshFailure;

  /// ما على الشاشة كما هو، ومعه سببُ فشل إعادة التحميل.
  TreasuryLoaded failedRefresh(Failure failure) => TreasuryLoaded(
    accounts: accounts,
    ownership: ownership,
    inventory: inventory,
    refreshFailure: failure,
  );

  /// الحالة نفسها بحساباتٍ رُقِّعت — بلا فشلٍ قديم يُقال من جديد.
  TreasuryLoaded withAccounts(TreasuryAccounts accounts) =>
      TreasuryLoaded(accounts: accounts, ownership: ownership, inventory: inventory);
}
