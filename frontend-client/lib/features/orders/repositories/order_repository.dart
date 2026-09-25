import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';

/// «طلباتي» — and placing one.
abstract interface class OrderRepository {
  /// One page of the customer's own orders, most recent first.
  ///
  /// **No customer id is sent, and none could be.** The server resolves it from the token, so
  /// there is nothing here to point at somebody else's orders.
  ///
  /// [openOnly] narrows to the ones still moving, and [stage] to a single one. It is asked in
  /// *stages* — the customer's
  /// vocabulary — and the server translates; this app never learns the workshop's statuses.
  Future<Either<Failure, Paginated<CustomerOrder>>> list({
    int page,
    bool openOnly,
    String? stage,
  });

  /// One order, with its lines, what is owed, and the stages it has passed.
  Future<Either<Failure, CustomerOrderDetail>> detail(int id);

  /// Places an order.
  ///
  /// **It is born «بانتظار المراجعة», not «جديدة».** «جديدة» means a person checked it — a clerk
  /// who typed an order down spoke to the customer first — and from there the next move takes
  /// goods off the shelf. Nothing checked this one, so it waits to be read. The screen should
  /// say so rather than implying the order is confirmed.
  Future<Either<Failure, CustomerOrderDetail>> place(NewOrder order);

  /// يسعّر سلةً قبل إرسالها، بالطريق الذي تُسعَّر به الطلبية — ولا يكتب شيئاً.
  ///
  /// [cityId] يضيف رسم التوصيل إليها حين تُختار المدينة.
  Future<Either<Failure, BasketQuote>> quote({required List<NewOrderLine> items, int? cityId});
}
