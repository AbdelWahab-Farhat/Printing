import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/employee_wallet/usecases/employee_wallet_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_wallet_cubit.freezed.dart';
part 'my_wallet_state.dart';

/// رصيدُ محفظة القارئ نفسه: رأس «محفظتي»، والسطر على الرئيسية وفوق طابور المصمم.
///
/// **قراءةٌ فقط**: لا يحرّك أحدٌ محفظته من هنا، فلا كتابة في هذا الـ Cubit.
class MyWalletCubit extends Cubit<MyWalletState> {
  MyWalletCubit({required GetMyWallet getWallet})
    : _getWallet = getWallet,
      super(const MyWalletState.loading());

  final GetMyWallet _getWallet;

  int _requestId = 0;

  Future<void> load() async {
    final requestId = ++_requestId;
    final previous = switch (state) {
      MyWalletLoaded(:final balance) => balance,
      _ => null,
    };

    if (state is MyWalletFailed) emit(const MyWalletState.loading());

    final result = await _getWallet();

    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        (failure) => previous == null
            ? MyWalletState.failed(failure)
            : MyWalletState.loaded(previous, refreshFailure: failure),
        (wallet) => MyWalletState.loaded(wallet.balance),
      ),
    );
  }

  /// الرصيد كما قرأته «محفظتي» — يُرسم بلا طلب، ويُسقط أيَّ قراءةٍ أقدم منه في الطريق.
  void show(String balance) {
    _requestId++;

    if (!isClosed) emit(MyWalletState.loaded(balance));
  }
}
