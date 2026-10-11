import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// رأس محفظة العميل: رصيدها، والكتابتان من المكتب — الشحن والتعديل.
///
/// **بجانب [WalletEntriesCubit] لا مدمجٌ فيه**، كرأس صفحة الحساب: السجل يُصفَّح والرأس لا. كلُّ
/// كتابةٍ تعود بالسطر الذي كتبه الخادم والرصيد بعده — الرأس يأخذ الرصيد، والسجلُّ يضيف السطر.
///
/// ويحفظ [moneyMoved] — ما تعيده الصفحة لشاشة العميل حين تُغلق، فتقرأ رصيدها من جديد.
class CustomerWalletCubit extends Cubit<CustomerWalletState> {
  CustomerWalletCubit({
    required this.customerId,
    required GetCustomerWallet getWallet,
    required TopUpCustomerWallet topUp,
    required AdjustCustomerWallet adjust,
  }) : _getWallet = getWallet,
       _topUp = topUp,
       _adjust = adjust,
       super(const CustomerWalletLoading());

  final int customerId;
  final GetCustomerWallet _getWallet;
  final TopUpCustomerWallet _topUp;
  final AdjustCustomerWallet _adjust;

  /// تحرّك مالٌ منذ فُتحت الصفحة.
  bool moneyMoved = false;

  int _requestId = 0;

  Future<void> load() async {
    final requestId = ++_requestId;
    final previous = switch (state) {
      final CustomerWalletLoaded loaded => loaded,
      _ => null,
    };

    if (state is CustomerWalletFailed) emit(const CustomerWalletLoading());

    final result = await _getWallet(customerId);

    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        // ما على الشاشة يبقى، والفشل يُقال في توست.
        (failure) => previous == null
            ? CustomerWalletFailed(failure)
            : CustomerWalletLoaded(previous.balance, refreshFailure: failure),
        (wallet) => CustomerWalletLoaded(wallet.balance),
      ),
    );
  }

  Future<Either<Failure, WalletWrite>> topUp({
    required String amount,
    required TopUpMethod method,
    int? treasuryAccountId,
    String? reference,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
  }) async {
    final result = await _topUp(
      customerId,
      amount: amount,
      method: method,
      treasuryAccountId: treasuryAccountId,
      reference: reference,
      notes: notes,
      receiptPath: receiptPath,
      receiptFilename: receiptFilename,
    );

    result.fold((_) {}, (write) => applyBalance(write.balance));

    return result;
  }

  Future<Either<Failure, WalletWrite>> adjust({
    required String amount,
    required bool credit,
    required String reason,
  }) async {
    final result = await _adjust(customerId, amount: amount, credit: credit, reason: reason);

    result.fold((_) {}, (write) => applyBalance(write.balance));

    return result;
  }

  /// الرصيد كما قاله الخادم بعد كتابةٍ — هنا أو من السجل (عكس).
  void applyBalance(String balance) {
    moneyMoved = true;

    if (!isClosed) emit(CustomerWalletLoaded(balance));
  }
}

sealed class CustomerWalletState {
  const CustomerWalletState();
}

final class CustomerWalletLoading extends CustomerWalletState {
  const CustomerWalletLoading();
}

final class CustomerWalletFailed extends CustomerWalletState {
  const CustomerWalletFailed(this.failure);

  final Failure failure;
}

final class CustomerWalletLoaded extends CustomerWalletState {
  const CustomerWalletLoaded(this.balance, {this.refreshFailure});

  final String balance;

  /// إعادةُ تحميلٍ فشلت والرأس باقٍ على ما قبلها: يقوله توست.
  final Failure? refreshFailure;
}
