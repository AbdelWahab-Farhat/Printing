import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/usecases/get_customers.dart';

/// The list of customers, searchable by name, code or phone.
///
/// Everything a paged list does — the debounce, the out-of-order guard, appending pages, keeping
/// the list when a page fails — comes from [PagedCubit]. All that is left is *what to fetch*,
/// which is the only part that is about customers.
///
/// [onlyActive] separates the two screens that use it: the العملاء tab is the record and shows
/// everyone including the ones the shop stopped selling to, while the picker behind «طلبية
/// جديدة» asks a narrower question that a deactivated customer is never the answer to.
class CustomersCubit extends PagedCubit<Customer> {
  CustomersCubit({required GetCustomers getCustomers, bool onlyActive = false})
    : _getCustomers = getCustomers,
      _onlyActive = onlyActive;

  final GetCustomers _getCustomers;
  final bool _onlyActive;

  CustomersFilter _filter = CustomersFilter.none;

  /// What the filter sheet is currently set to — read by the button that opens it, so it opens
  /// on the answers already given rather than on a blank sheet.
  CustomersFilter get filter => _filter;

  /// Applies what «تطبيق» handed back and reloads from page one.
  ///
  /// **From page one, and with the term still in the box.** A filter applied to page four would
  /// leave three pages of the old question above it, and clearing the search would undo a
  /// narrowing the user can still see in the box in front of them.
  ///
  /// A no-op when nothing changed: the sheet returns a fresh instance on every «تطبيق», and
  /// reloading a list for a tap that answered the same way is a skeleton somebody watches for
  /// no reason.
  Future<void> applyFilter(CustomersFilter filter) async {
    if (filter == _filter) return;

    _filter = filter;
    await load(search: currentSearch);
  }

  @override
  Future<Either<Failure, Paginated<Customer>>> fetchPage({String? search, required int page}) {
    return _getCustomers(
      search: search,
      // Null rather than false: false would ask for the deactivated ones only.
      isActive: _onlyActive ? true : null,
      // Carried on every page, including the ones `loadMore` asks for: page two of «بدون طلبات»
      // must not arrive as page two of everybody.
      hasOrders: _filter.hasOrders,
      sort: _filter.sort,
      page: page,
    );
  }
}

/// The state this screen switches on. A name for `PagedState<Customer>`, so the view reads as a
/// customers screen while there is one implementation behind every list in the app.
typedef CustomersState = PagedState<Customer>;
typedef CustomersInitial = PagedInitial<Customer>;
typedef CustomersLoading = PagedLoading<Customer>;
typedef CustomersLoaded = PagedLoaded<Customer>;
typedef CustomersFailure = PagedFailure<Customer>;
