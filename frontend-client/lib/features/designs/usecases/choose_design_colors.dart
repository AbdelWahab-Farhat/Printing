import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/print_colors/print_color.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';

/// Choose a design's «ألوان الطباعة» — a name and a swatch each. Our team adds the codes, and
/// once it has the list is no longer the customer's to change.
class ChooseDesignColors {
  const ChooseDesignColors(this._repository);

  final DesignRepository _repository;

  Future<Either<Failure, CustomerDesign>> call({
    required int id,
    required List<PrintColor> colors,
  }) => _repository.setColors(id: id, colors: colors);
}
