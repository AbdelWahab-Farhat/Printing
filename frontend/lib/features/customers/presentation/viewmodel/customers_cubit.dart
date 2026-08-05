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
class CustomersCubit extends PagedCubit<Customer> {
  CustomersCubit({required GetCustomers getCustomers}) : _getCustomers = getCustomers;

  final GetCustomers _getCustomers;

  @override
  Future<Either<Failure, Paginated<Customer>>> fetchPage({String? search, required int page}) {
    return _getCustomers(search: search, page: page);
  }
}

/// The state this screen switches on. A name for `PagedState<Customer>`, so the view reads as a
/// customers screen while there is one implementation behind every list in the app.
typedef CustomersState = PagedState<Customer>;
typedef CustomersInitial = PagedInitial<Customer>;
typedef CustomersLoading = PagedLoading<Customer>;
typedef CustomersLoaded = PagedLoaded<Customer>;
typedef CustomersFailure = PagedFailure<Customer>;
