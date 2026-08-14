import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/products/models/product_category.dart';

/// Reading and curating التصنيفات, stated without saying how.
abstract interface class ProductCategoryRepository {
  /// One page of categories, in the catalogue's own order.
  ///
  /// [isActive] left null returns both the offered and the stopped ones — which is what the
  /// management screen wants. A picker asks for `true`.
  /// [leafOnly] narrows it to the headings a product may actually be filed under — one holding
  /// subheadings is a heading, not a slot. What the product form's picker asks for.
  Future<Either<Failure, Paginated<ProductCategory>>> categories({
    String? search,
    bool? isActive,
    bool leafOnly = false,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, ProductCategory>> create({
    required String name,
    String? description,
    required int sortOrder,
  });

  Future<Either<Failure, ProductCategory>> update(
    int categoryId, {
    required String name,
    String? description,
    required int sortOrder,
    required bool isActive,
  });

  /// Hides a category from the pickers. The products already under it keep it.
  Future<Either<Failure, ProductCategory>> setActivation(
    int categoryId, {
    required bool isActive,
  });

  /// Puts the headings in the order they were dragged into.
  ///
  /// **The whole order in one call.** A drag moves one card and renumbers everything after it;
  /// a request per moved row would be a burst of writes where one is needed, and a dropped
  /// connection halfway would leave the list in an order nobody chose. Answers with the
  /// server's own message.
  Future<Either<Failure, String>> reorder(List<int> orderedIds);

  /// Sets the picture the catalogue prints above a heading, replacing whatever was there.
  ///
  /// [onProgress] is called as the bytes go out — given rather than a `Stream` because there is
  /// exactly one listener, the sheet showing the bar, and a stream would need closing.
  Future<Either<Failure, ProductCategory>> setImage(
    int categoryId, {
    required String path,
    required String filename,
    void Function(int sent, int total)? onProgress,
  });

  /// Takes the picture off. Idempotent on the server, so a retry after a dropped connection is
  /// free.
  Future<Either<Failure, ProductCategory>> removeImage(int categoryId);

  /// Only for a row that should never have existed. The server refuses with 422 once any
  /// product points at the category — deactivation is what retires one in use. Answers with the
  /// server's own message, so the screen says what happened in the words the API chose.
  Future<Either<Failure, String>> delete(int categoryId);
}
