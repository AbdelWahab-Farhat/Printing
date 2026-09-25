import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/pagination/paged_cubit.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/usecases/browse_orders.dart';

/// The list «طلباتي» is bound to.
typedef OrdersState = PagedState<CustomerOrder>;

/// The ViewModel for «طلباتي».
///
/// **The paging is inherited, not written here.** Debounce, the out-of-order guard, appending
/// without duplicating a row that moved between pages, and keeping the list when page three
/// fails all live in [PagedCubit] — every one of them is a bug somebody has shipped by
/// forgetting it, and a second copy in this file would be a second chance to.
///
/// ما يبقى هنا هو ما تنفرد به هذه القائمة: تُسأل بالمراحل، و[OrdersFilter] هو حيث يصير كل
/// اختيارٍ من الأحد عشر قيمةَ `stage=` التي يأخذها الـ API.
class OrdersCubit extends PagedCubit<CustomerOrder> {
  OrdersCubit({required BrowseOrders browse}) : _browse = browse;

  final BrowseOrders _browse;

  OrdersFilter _filter = OrdersFilter.all;

  /// الحالة المختارة.
  OrdersFilter get filter => _filter;

  /// **No `search` reaches the wire.** «طلباتي» has no search endpoint — a customer holds tens
  /// of orders, not thousands — so the parameter is accepted to satisfy the base class and
  /// deliberately dropped. Passing it would be this app inventing a filter the server does not
  /// implement and would silently ignore.
  @override
  Future<Either<Failure, Paginated<CustomerOrder>>> fetchPage({
    String? search,
    required int page,
  }) => _browse(page: page, stage: _filter.stageParameter);

  @override
  Object identityOf(CustomerOrder item) => item.id;

  /// **An order that leaves the filter while it is on screen leaves the list.** Leaving it there
  /// would make the chip a lie until the next refresh — see `PagedCubit.belongs`.
  @override
  bool belongs(CustomerOrder item) => _filter.admits(item);

  /// Narrows the list, or widens it back to everything.
  Future<void> narrowTo(OrdersFilter filter) {
    if (filter == _filter) return Future<void>.value();

    _filter = filter;

    return load();
  }
}
