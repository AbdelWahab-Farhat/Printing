import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';

/// محفظةٌ في الذاكرة: رصيدٌ يُقرأ، ودفعٌ يُسجَّل وينقصه — للشاشات التي تقرأ «محفظتي» بلا Cubit.
class FakeWallet implements WalletRepository {
  FakeWallet({this.held = '0.00', this.owedAfterPay = '0.00'});

  /// ما في المحفظة.
  String held;

  /// الرصيد الذي يعيده الخادم بعد الدفع.
  final String owedAfterPay;

  /// الطلبيات التي دُفعت من المحفظة، بالترتيب.
  final List<int> paidOrders = [];

  /// رمزُ كلّ طلب دفعٍ وصل — ما نجح منه وما فشل.
  final List<String?> tokens = [];

  /// يُفشل الطلبَ التالي كاتصالٍ انقطع، ثم يعود إلى النجاح.
  bool dropNext = false;

  @override
  Future<Either<Failure, String>> balance() async => Right(held);

  @override
  Future<Either<Failure, Paginated<MyWalletEntry>>> entries({
    required int page,
    MyWalletFilter filter = MyWalletFilter.all,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, String>> payOrder(int orderId, {String? amount, String? clientToken}) async {
    tokens.add(clientToken);

    if (dropNext) {
      dropNext = false;

      return const Left(Failure.network(message: FailureMessages.noConnection));
    }

    paidOrders.add(orderId);
    held = owedAfterPay;

    return Right(held);
  }

  /// يسجّل حالتي الاستخدام اللتين تقرؤهما «حسابي» وشاشة الطلبية.
  void register() {
    sl
      ..registerLazySingleton<GetWalletBalance>(() => GetWalletBalance(this))
      ..registerLazySingleton<PayOrderFromWallet>(() => PayOrderFromWallet(this));
  }
}
