import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/repositories/online_payment_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart' show normaliseAmount;

class GetPaymentIntents {
  const GetPaymentIntents(this._repository);

  final OnlinePaymentRepository _repository;

  Future<Either<Failure, Paginated<PaymentIntent>>> call({
    required int page,
    IntentFilter filter = IntentFilter.all,
    String? search,
  }) => _repository.intents(page: page, filter: filter, search: search);
}

class RecheckPaymentIntent {
  const RecheckPaymentIntent(this._repository);

  final OnlinePaymentRepository _repository;

  Future<Either<Failure, PaymentIntent>> call(String uuid) => _repository.recheck(uuid);
}

class GetOnlinePaymentMethods {
  const GetOnlinePaymentMethods(this._repository);

  final OnlinePaymentRepository _repository;

  Future<Either<Failure, OnlinePaymentMethods>> call() => _repository.methods();
}

class UpdateOnlinePaymentMethod {
  const UpdateOnlinePaymentMethod(this._repository);

  final OnlinePaymentRepository _repository;

  /// [daily] و[monthly] و[yearly] كما كُتبت: الفارغُ «بلا حد».
  Future<Either<Failure, OnlinePaymentMethodSetting>> call(
    int id, {
    bool? isActive,
    String? daily,
    String? monthly,
    String? yearly,
    bool withLimits = false,
  }) => _repository.updateMethod(
    id,
    isActive: isActive,
    limits: withLimits
        ? {
            'daily_limit': _limit(daily),
            'monthly_limit': _limit(monthly),
            'yearly_limit': _limit(yearly),
          }
        : null,
  );

  static String? _limit(String? text) =>
      (text == null || text.trim().isEmpty) ? null : normaliseAmount(text);
}

class RecordEzonePayout {
  const RecordEzonePayout(this._repository);

  final OnlinePaymentRepository _repository;

  Future<Either<Failure, EzonePayout>> call({
    required String amount,
    String? kept,
    int? toAccountId,
    String? reference,
    required String clientToken,
  }) => _repository.recordPayout(
    amount: normaliseAmount(amount),
    kept: (kept == null || kept.trim().isEmpty) ? null : normaliseAmount(kept),
    toAccountId: toAccountId,
    reference: reference,
    clientToken: clientToken,
  );
}
