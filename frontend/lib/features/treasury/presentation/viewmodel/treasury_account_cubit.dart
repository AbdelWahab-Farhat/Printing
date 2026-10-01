import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/account_change.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// رأس صفحة الحساب: رصيده ومجاميعه بالنوع.
///
/// **Cubit مستقلٌّ بجانب [AccountMovementsCubit] لا مدمجٌ فيه:** السجل يُصفَّح والرأس لا. وكلٌّ
/// منهما يقرأ ما يخصّه بعد الكتابة — الرأس يُقرأ هنا مرةً واحدة، والسجل يُرقَّع بسطر.
///
/// ويحفظ [change] — ما تعيده الصفحة للّوحة حين تُغلق.
class TreasuryAccountCubit extends Cubit<TreasuryAccountState> {
  TreasuryAccountCubit({
    required this.accountId,
    required GetTreasuryAccount getAccount,
    required GetTreasuryAccounts getAccounts,
    required RecordTreasuryOperation recordOperation,
    required SaveTreasuryAccount saveAccount,
  }) : _getAccount = getAccount,
       _getAccounts = getAccounts,
       _recordOperation = recordOperation,
       _saveAccount = saveAccount,
       super(const TreasuryAccountLoading());

  final int accountId;
  final GetTreasuryAccount _getAccount;
  final GetTreasuryAccounts _getAccounts;
  final RecordTreasuryOperation _recordOperation;
  final SaveTreasuryAccount _saveAccount;

  bool _moneyMoved = false;
  TreasuryAccount? _edited;

  /// ما تغيّر منذ فُتحت الصفحة: مالٌ تحرّك يغلب التعديل، لأن قراءةً جديدة تغطّي الاثنين.
  AccountChange? get change => _moneyMoved
      ? const AccountMoneyMoved()
      : switch (_edited) {
          final TreasuryAccount account => AccountEdited(account),
          null => null,
        };

  int _requestId = 0;

  Future<void> load() async {
    final requestId = ++_requestId;
    final previous = switch (state) {
      final TreasuryAccountLoaded loaded => loaded,
      _ => null,
    };

    if (state is TreasuryAccountFailed) emit(const TreasuryAccountLoading());

    final result = await _getAccount(accountId);

    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        // ما على الشاشة يبقى، والفشل يُقال في توست.
        (failure) => previous == null
            ? TreasuryAccountFailed(failure)
            : TreasuryAccountLoaded(previous.detail, refreshFailure: failure),
        (detail) => TreasuryAccountLoaded(detail),
      ),
    );
  }

  /// عمليةٌ يدوية على هذا الحساب. تعود بالعملية التي كتبها الخادم، فيضيف السجلُّ سطرها.
  ///
  /// **الرأس يُقرأ هنا وحده، مرةً واحدة**: الرصيد والمجاميع حسابُ الخادم.
  Future<Either<Failure, TreasuryOperation>> record({
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

    if (result.isRight()) await moneyMoved();

    return result;
  }

  /// مالٌ تحرّك على هذا الحساب من غير [record] — عكسٌ من السجل: يُقرأ الرأس ويُذكر للّوحة.
  Future<void> moneyMoved() async {
    _moneyMoved = true;

    if (!isClosed) await load();
  }

  /// تعديل الحساب. **يُرسم من ردّ الحفظ نفسه** — الحساب فيه برصيده، والمجاميع لم تتغيّر لأن
  /// التعديل لا يحرّك مالاً.
  Future<Failure?> save({
    required String name,
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

    if (isClosed) return result.fold((failure) => failure, (_) => null);

    return result.fold((failure) => failure, (account) {
      _edited = account;

      if (state case final TreasuryAccountLoaded loaded) {
        emit(TreasuryAccountLoaded(loaded.detail.withAccount(account)));
      }

      return null;
    });
  }

  /// الحسابات التي يُحوَّل إليها: كل حسابٍ مفعّل. **الفشل يعود فشلاً**، فلا يُفتح التحويل على
  /// حسابٍ واحد لا يُحوَّل منه إلى شيء.
  Future<Either<Failure, List<TreasuryAccount>>> transferTargets() async {
    final result = await _getAccounts(activeOnly: true);

    return result.map((list) => list.accounts);
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
  const TreasuryAccountLoaded(this.detail, {this.refreshFailure});

  final TreasuryAccountDetail detail;

  /// إعادةُ تحميلٍ فشلت والرأس باقٍ على ما قبلها: يقوله توست.
  final Failure? refreshFailure;
}

/// سجلّ الحساب، الأحدث أولاً، مصفّى بالنوع والتاريخ على الخادم.
///
/// **يُرقَّع ولا يُعاد.** ما يكتبه الخادم بعد عمليةٍ أو عكسٍ سطرٌ واحد في أعلاه، فيُقرأ ذلك السطر
/// وحده ([addWrittenBy]) — معرّفه ورصيده بعده جوابُ الخادم لا يخترعه التطبيق — وتبقى الصفحات
/// المحمّلة ومكانُ التمرير.
class AccountMovementsCubit extends PagedCubit<TreasuryMovement> {
  AccountMovementsCubit({
    required this.accountId,
    required GetAccountMovements getMovements,
    required ReverseTreasuryOperation reverseOperation,
  }) : _getMovements = getMovements,
       _reverseOperation = reverseOperation;

  final int accountId;
  final GetAccountMovements _getMovements;
  final ReverseTreasuryOperation _reverseOperation;

  String? _kind;
  DateTime? _from;
  DateTime? _to;

  /// نوع الحركة المختار — `deposit`، `payment`… — أو null للكل.
  String? get kind => _kind;
  DateTime? get from => _from;
  DateTime? get to => _to;

  /// اختيار المختار نفسه لا يعيد القراءة.
  Future<void> filterBy(String? kind) async {
    if (kind == _kind) return;
    _kind = kind;

    return load();
  }

  /// الطرفان داخلان؛ null فيهما يمسح المدى.
  Future<void> between(DateTime? from, DateTime? to) {
    _from = from;
    _to = to;

    return load();
  }

  /// يعكس العملية التي كتبت [original]. null عند النجاح، والرفضُ غير ذلك.
  ///
  /// الأصل يُعلَّم معكوساً في مكانه، وسطرُ العكس يُقرأ من الخادم ويوضع أعلى السجل.
  Future<Failure?> reverse(TreasuryMovement original, {required String reason}) async {
    final operationId = original.operationId;

    if (operationId == null) return null;

    final result = await _reverseOperation(operationId, reason: reason);

    return result.fold((failure) => failure, (reversal) async {
      replace(original.markedReversed());
      await _addNewest(operationId: reversal.id, kind: original.kind);

      return null;
    });
  }

  /// يضع أعلى السجل السطرَ الذي كتبته [operation] على هذا الحساب.
  Future<void> addWrittenBy(TreasuryOperation operation) =>
      _addNewest(operationId: operation.id, kind: operation.type);

  /// يقرأ أحدث سطرٍ من [kind] — ما كُتب للتوّ — ويضعه في أعلى السجل.
  ///
  /// **إن لم يكن سطرَ [operationId]** فقد كُتب غيره على الحساب في اللحظة نفسها، فيُقرأ السجل كله
  /// مرةً واحدة. وإن فشلت القراءة بقي ما على الشاشة: السطر يظهر مع السحب التالي.
  Future<void> _addNewest({required int operationId, required String kind}) async {
    // سطرٌ من نوعٍ غير المختار لا مكان له في هذا السجل أصلاً.
    if (_kind != null && _kind != kind) return;

    final result = await _getMovements(accountId, page: 1, perPage: 1, kind: kind);

    if (isClosed) return;

    final newest = result.fold((_) => null, (page) => page.items.firstOrNull);

    if (result.isLeft()) return;

    if (newest == null || newest.operationId != operationId) {
      await refresh();

      return;
    }

    insert(newest);
  }

  @override
  Object identityOf(TreasuryMovement item) => item.id;

  /// سطرٌ رُقِّع يغادر فلتراً لم يعد يطابقه — نوعاً أو مدى أيام.
  @override
  bool belongs(TreasuryMovement item) {
    if (_kind != null && item.kind != _kind) return false;

    final at = item.occurredAt;

    if (at == null) return _from == null && _to == null;

    final day = DateTime(at.year, at.month, at.day);

    if (_from case final from? when day.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }

    if (_to case final to? when day.isAfter(DateTime(to.year, to.month, to.day))) return false;

    return true;
  }

  @override
  Future<Either<Failure, Paginated<TreasuryMovement>>> fetchPage({
    String? search,
    required int page,
  }) => _getMovements(accountId, page: page, kind: _kind, from: _from, to: _to);
}

typedef AccountMovementsState = PagedState<TreasuryMovement>;
