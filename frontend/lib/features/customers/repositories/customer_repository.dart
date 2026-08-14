import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/models/new_customer.dart';

/// What the app can do about customers, stated without saying how.
///
/// The Cubit depends on *this*, which is the whole reason the abstraction is kept: a test hands
/// it a fake in one line and never constructs Dio. Swapping the transport, or putting a cache
/// in front of it, is a change below this line with nothing above it to update.
abstract interface class CustomerRepository {
  /// One page of customers, newest first.
  ///
  /// [search] matches the name, the code *or* the phone number — the API's rule, not one
  /// re-implemented here. [isActive] left null returns both active and deactivated customers,
  /// which is what a staff list wants: a deactivated customer you cannot find is a support call.
  ///
  /// [hasOrders] and [sort] are the two the server answers out of the *orders*, and both need
  /// `orders.view`: `false` gives «زبائن بدون طلب», and [CustomersSort.leastRecentOrder] puts
  /// the customer nobody has heard from for longest at the top and carries a `lastOrderAt` on
  /// every row. A caller without that permission gets a 403 rather than a quietly wider list,
  /// which is why the screen hides the sheet rather than sending the request and coping.
  Future<Either<Failure, Paginated<Customer>>> customers({
    String? search,
    bool? isActive,
    bool? hasOrders,
    CustomersSort sort = CustomersSort.newest,
    int page = 1,
    int perPage = 20,
  });

  /// Registers a new customer — with their shops, if any were given — and returns them as the
  /// server stored them.
  ///
  /// `code` comes back allocated (`C1`, `C2`, …) — it is generated server-side and there is no
  /// way to propose one from here.
  ///
  /// `is_active` is deliberately absent from [NewCustomer]: a customer being created is one you
  /// have just started working with, and the API defaults them to active. When deactivating gets
  /// a screen, it belongs on the customer that already exists, not on the form that creates them.
  Future<Either<Failure, Customer>> create(NewCustomer customer);

  /// One customer with their shops.
  ///
  /// A second request rather than a row lifted out of the list: the list carries no shops, and
  /// a detail screen built from a stale list row would show yesterday's phone number.
  Future<Either<Failure, Customer>> customer(int customerId);

  /// Saves changes to an existing customer, and answers with them as the server stored them.
  ///
  /// **Shops are synced, not appended.** A shop carrying an id is updated, one without is
  /// created, and one the payload leaves out is deleted — so the payload must always carry the
  /// complete list, and an empty list genuinely means "remove them all".
  ///
  /// `is_active` is deliberately not part of this: see [setActivation].
  Future<Either<Failure, Customer>> update(int customerId, NewCustomer customer);

  /// Turns a customer on or off.
  ///
  /// Its own endpoint rather than a field on [update], and that is a safety property rather
  /// than tidiness: because saving an edit never carries `is_active`, editing a deactivated
  /// customer can never silently switch them back on.
  Future<Either<Failure, Customer>> setActivation(int customerId, {required bool isActive});
}
