import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';

/// Replaces a design's «ألوان الطباعة» — the inks it is printed in. An empty list clears them.
///
/// **It reaches the orders still waiting to print this design**, on the server: every order
/// holds a copy of the colors, and the copy follows the library until the order goes to the
/// press. An order that was given colors of its own keeps them. See PRINT-COLORS.md.
class SetCustomerDesignColors {
  const SetCustomerDesignColors(this._repository);

  final CustomerDesignRepository _repository;

  Future<Either<Failure, CustomerDesign>> call(
    int customerId,
    int designId,
    List<PrintColor> colors,
  ) => _repository.setPrintColors(customerId, designId, colors);
}
