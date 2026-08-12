import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/usecases/get_customers.dart';

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

  @override
  Future<Either<Failure, Paginated<Customer>>> fetchPage({String? search, required int page}) {
    return _getCustomers(
      search: search,
      // Null rather than false: false would ask for the deactivated ones only.
      isActive: _onlyActive ? true : null,
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
