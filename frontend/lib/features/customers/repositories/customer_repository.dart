import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/customers/models/customer.dart';

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
  Future<Either<Failure, Paginated<Customer>>> customers({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  /// Registers a new customer and returns them as the server stored them.
  ///
  /// `code` comes back allocated (`C1`, `C2`, …) — it is generated server-side and there is no
  /// way to propose one from here.
  ///
  /// `is_active` is deliberately not a parameter: a customer being created is one you have just
  /// started working with, and the API defaults them to active. When deactivating gets a
  /// screen, it belongs on the customer that already exists, not on the form that creates them.
  Future<Either<Failure, Customer>> create({
    required String name,
    required String phone,
  });
}
