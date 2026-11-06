import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/usecases/employee_wallet_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_wallet_cubit.freezed.dart';
part 'employee_wallet_state.dart';

/// رأس محفظة موظف: رصيدها، والكتابات الأربع — الإيداع والمستحق والسحب والتعديل.
///
/// **بجانب [EmployeeWalletEntriesCubit] لا مدمجٌ فيه**، كرأس محفظة العميل: السجل يُصفَّح والرأس لا.
/// كلُّ كتابةٍ تعود بالسطر الذي كتبه الخادم والرصيد بعده: الرأس يأخذ الرصيد، والسجلُّ يضيف السطر.
///
/// ويحفظ [moneyMoved]: الصفحة تسلّم الرصيد لمن فتحها حين تحرّك مال، فيرقّع صفّه بلا طلب.
class EmployeeWalletCubit extends Cubit<EmployeeWalletState> {
  EmployeeWalletCubit({
    required this.userId,
    required GetEmployeeWallet getWallet,
    required DepositToEmployeeWallet deposit,
    required CreditEmployeeWallet credit,
    required WithdrawFromEmployeeWallet withdraw,
    required AdjustEmployeeWallet adjust,
  }) : _getWallet = getWallet,
       _deposit = deposit,
       _credit = credit,
       _withdraw = withdraw,
       _adjust = adjust,
       super(const EmployeeWalletState.loading());

  final int userId;
  final GetEmployeeWallet _getWallet;
  final DepositToEmployeeWallet _deposit;
  final CreditEmployeeWallet _credit;
  final WithdrawFromEmployeeWallet _withdraw;
  final AdjustEmployeeWallet _adjust;

  /// تحرّك مالٌ منذ فُتحت الصفحة.
  bool moneyMoved = false;

  int _requestId = 0;

  Future<void> load() async {
    final requestId = ++_requestId;
    final previous = switch (state) {
      EmployeeWalletLoaded(:final wallet) => wallet,
      _ => null,
    };

    if (state is EmployeeWalletFailed) emit(const EmployeeWalletState.loading());

    final result = await _getWallet(userId);

    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        // ما على الشاشة يبقى، والفشل يُقال في توست.
        (failure) => previous == null
            ? EmployeeWalletState.failed(failure)
            : EmployeeWalletState.loaded(previous, refreshFailure: failure),
        (wallet) => EmployeeWalletState.loaded(wallet),
      ),
    );
  }

  Future<Either<Failure, EmployeeWalletWrite>> deposit(
    EmployeeMoneyDraft draft, {
    required String clientToken,
  }) => _written(_deposit(userId, draft, clientToken: clientToken));

  Future<Either<Failure, EmployeeWalletWrite>> credit(
    EmployeeCreditDraft draft, {
    required String clientToken,
  }) => _written(_credit(userId, draft, clientToken: clientToken));

  Future<Either<Failure, EmployeeWalletWrite>> withdraw(
    EmployeeMoneyDraft draft, {
    required String clientToken,
  }) => _written(_withdraw(userId, draft, clientToken: clientToken));

  Future<Either<Failure, EmployeeWalletWrite>> adjust({
    required String amount,
    required bool credit,
    required String reason,
    required String clientToken,
  }) => _written(
    _adjust(userId, amount: amount, credit: credit, reason: reason, clientToken: clientToken),
  );

  Future<Either<Failure, EmployeeWalletWrite>> _written(
    Future<Either<Failure, EmployeeWalletWrite>> write,
  ) async {
    final result = await write;

    result.fold((_) {}, (written) => applyBalance(written.balance));

    return result;
  }

  /// الرصيد كما قاله الخادم بعد كتابةٍ — هنا، أو من السجل (عكس)، أو من صفحة المحفظة لصفّها.
  ///
  /// **يُسقط أيَّ قراءةٍ في الطريق**: بدأت قبل الكتابة، فما ستعود به رصيدٌ قديم.
  void applyBalance(String balance) {
    moneyMoved = true;
    _requestId++;

    if (isClosed) return;

    emit(
      EmployeeWalletState.loaded(switch (state) {
        EmployeeWalletLoaded(:final wallet) => wallet.copyWith(balance: balance),
        _ => EmployeeWallet(balance: balance),
      }),
    );
  }
}
