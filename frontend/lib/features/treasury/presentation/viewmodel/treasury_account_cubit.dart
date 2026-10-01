import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/account_change.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// رأس صفحة الحساب: رصيده.
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

/// سجلّ الحساب، الأحدث أولاً، مقصوراً على الخادم بـ[filter] — الكل، مال الطلبيات، المصاريف —
/// وبالبحث برقم الطلبية (`PagedCubit.search`). طلب المستخدم (2026-10-01) بدل صفّ المجاميع.
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

  MovementFilter filter = MovementFilter.all;

  /// فلترٌ آخر — والبحثُ المكتوب يبقى معه.
  Future<void> narrowTo(MovementFilter value) {
    if (value == filter) return Future<void>.value();

    filter = value;

    return load(search: currentSearch);
  }

  /// يعكس عمليةَ السطر: يُعلَّم الأصلُ معكوساً في مكانه، ويُلحق سطرُ العكس الذي كتبه الخادم.
  Future<Failure?> reverse(TreasuryMovement original, {required String reason}) async {
    final operationId = original.operationId;

    if (operationId == null) return null;

    final result = await _reverseOperation(operationId, reason: reason);

    return result.fold((failure) => failure, (reversal) async {
      replace(original.markedReversed());
      await _addNewest(operationId: reversal.id);

      return null;
    });
  }

  /// ما كتبته عمليةٌ سُجّلت من هذه الصفحة.
  Future<void> addWrittenBy(TreasuryOperation operation) => _addNewest(operationId: operation.id);

  /// أحدثُ سطرٍ في الحساب كلِّه — إن كان من هذه العملية أُلحق، وإلا فقد كتب غيرُها بينهما
  /// فيُعاد السجل. وسطرٌ لا يطابق الفلتر أو البحث لا مكان له هنا أصلاً ([belongs]).
  Future<void> _addNewest({required int operationId}) async {
    final result = await _getMovements(accountId, page: 1, perPage: 1);

    if (isClosed || result.isLeft()) return;

    final newest = result.fold((_) => null, (page) => page.items.firstOrNull);

    if (newest == null || newest.operationId != operationId) {
      await refresh();

      return;
    }

    insert(newest);
  }

  @override
  Object identityOf(TreasuryMovement item) => item.id;

  @override
  bool belongs(TreasuryMovement item) {
    final fits = switch (filter) {
      MovementFilter.all => true,
      MovementFilter.orders => item.orderId != null,
      MovementFilter.expenses => item.kind == 'expense',
    };

    if (!fits) return false;

    // البحثُ رقمُ طلبيةٍ كاملاً، كما يطابقه الخادم — بالأرقام العربية أيضاً.
    final term = currentSearch?.trim();

    if (term == null || term.isEmpty) return true;

    return item.orderId != null && '${item.orderId}' == Validators.toWesternDigits(term);
  }

  @override
  Future<Either<Failure, Paginated<TreasuryMovement>>> fetchPage({
    String? search,
    required int page,
  }) => _getMovements(accountId, page: page, filter: filter, search: search);
}

typedef AccountMovementsState = PagedState<TreasuryMovement>;
