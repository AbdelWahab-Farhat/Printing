import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';

/// Puts the catalogue's headings in the order somebody just dragged them into.
///
/// **The whole order travels, not the one card that moved.** A drag renumbers everything after
/// the card it moved, and sending the moved row alone would leave the server guessing what the
/// rest now means.
class ReorderProductCategories {
  const ReorderProductCategories(this._repository);

  final ProductCategoryRepository _repository;

  Future<Either<Failure, String>> call(List<int> orderedIds) =>
      _repository.reorder(orderedIds);
}
