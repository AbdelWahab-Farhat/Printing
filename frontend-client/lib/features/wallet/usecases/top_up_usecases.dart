import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/repositories/top_up_repository.dart';

/// «1٢٥٫5» → «125.5»: ما يكتبه الزبون على لوحة عربية، بالشكل الذي يقبله الخادم.
String topUpAmount(String typed) =>
    Validators.toWesternDigits(typed.trim()).replaceAll('٫', '.').replaceAll(',', '.');

class GetTopUpMethods {
  const GetTopUpMethods(this._repository);

  final TopUpRepository _repository;

  Future<Either<Failure, TopUpMethods>> call() => _repository.methods();
}

class QuoteTopUp {
  const QuoteTopUp(this._repository);

  final TopUpRepository _repository;

  Future<Either<Failure, TopUpQuote>> call({required int method, required String amount}) =>
      _repository.quote(method: method, amount: topUpAmount(amount));
}

class StartTopUp {
  const StartTopUp(this._repository);

  final TopUpRepository _repository;

  Future<Either<Failure, TopUpAnswer>> call(TopUpRequest request) => _repository.start(request);
}

class ConfirmTopUpOtp {
  const ConfirmTopUpOtp(this._repository);

  final TopUpRepository _repository;

  Future<Either<Failure, TopUpAnswer>> call(String attemptId, String otp) =>
      _repository.confirmOtp(attemptId, Validators.toWesternDigits(otp));
}

class GetTopUpAttempt {
  const GetTopUpAttempt(this._repository);

  final TopUpRepository _repository;

  Future<Either<Failure, TopUpAnswer>> call(String attemptId) => _repository.show(attemptId);
}
