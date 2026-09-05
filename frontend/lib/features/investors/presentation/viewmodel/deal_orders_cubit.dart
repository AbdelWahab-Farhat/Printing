import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/features/investors/models/deal_order.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';

/// The orders that sold one deal's goods.
///
/// No search and no filter: the list is already narrowed to one deal, and what a person wants
/// from it is the whole of it in order.
class DealOrdersCubit extends PagedCubit<DealOrder> {
  DealOrdersCubit({required GetDealOrders getOrders}) : _getOrders = getOrders;

  final GetDealOrders _getOrders;

  late final int _dealId;

  /// Which deal's orders — set once, when the screen opens.
  Future<void> open(int dealId) {
    _dealId = dealId;

    return load();
  }

  @override
  Object identityOf(DealOrder item) => item.orderId;

  @override
  Future<Either<Failure, Paginated<DealOrder>>> fetchPage({
    String? search,
    required int page,
  }) => _getOrders(_dealId, page: page);
}
