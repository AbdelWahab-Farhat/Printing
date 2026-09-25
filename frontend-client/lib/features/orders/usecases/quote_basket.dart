import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';

/// يسعّر السلة من الخادم قبل إرسالها، والتوصيل إلى [cityId] حين تُختار المدينة.
class QuoteBasket {
  const QuoteBasket(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, BasketQuote>> call({
    required List<NewOrderLine> items,
    int? cityId,
  }) => _repository.quote(items: items, cityId: cityId);
}
