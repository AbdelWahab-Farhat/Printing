import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/files/picked_file.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/products/models/new_product.dart';
import 'package:printing/features/products/models/price_quote.dart';
import 'package:printing/features/products/models/product.dart';

/// Reading the catalogue, stated without saying how.
abstract interface class ProductRepository {
  /// One page of products, in catalogue order.
  ///
  /// [search] matches the name or the slug — the API's rule, not one re-implemented here. It
  /// does **not** match the pricing unit: "كيلو" finds nothing, which is why [pricingUnit]
  /// exists as a filter of its own rather than as something to type.
  ///
  /// [pricingUnit] is `piece` or `kilogram`; [isActive] left null returns both active and
  /// inactive products.
  Future<Either<Failure, Paginated<Product>>> products({
    String? search,
    String? category,
    /// «التصنيف» — the catalogue heading. Null means every heading.
    int? productCategoryId,
    String? pricingUnit,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  /// One product with everything on it — every variant, every price break, every photo.
  Future<Either<Failure, Product>> product(int productId);

  /// "What does this many of this size cost?"
  ///
  /// **The price is never worked out in the app**, even though the tiers are right there on
  /// [Product]: the server decides it in one place, and an order's line is written from that
  /// same code. Reading the ladder here to save a request would be a second implementation of
  /// pricing, and the day the two disagree is the day a customer is quoted one number and
  /// invoiced another.
  ///
  /// [quantity] is a decimal string, already in ASCII digits — a quantity typed on a Libyan
  /// keyboard has to be normalised before it gets here, because every numeric rule on the
  /// server is ASCII-only.
  ///
  /// Refusals are ordinary answers, not faults: a quote-only product, a quantity under the
  /// minimum and a size with no tier for it all come back as a [Failure] carrying the server's
  /// own Arabic sentence, which is what the screen shows.
  Future<Either<Failure, PriceQuote>> quote({
    required int productId,
    required int variantId,
    required String quantity,
  });

  /// Adds a product to the catalogue, and answers with the one the server stored.
  ///
  /// The answer matters: it carries the `code` the server allocated, which is the name staff
  /// will use for this bag from now on. Nothing the app made up is returned here.
  ///
  /// **[image] is required, and that is the server's rule rather than this app's.** A product
  /// cannot be created without a photo, so the two travel together in one `multipart` request:
  /// there is no moment where a product exists and its picture has still to be uploaded, and
  /// therefore no half-created product to clean up when the second request fails.
  Future<Either<Failure, Product>> create(
    NewProduct product, {
    required PickedFile image,
  });

  /// Rewrites a product, and answers with the one the server stored.
  ///
  /// **The variant list replaces rather than merges**, which is why every size the form still
  /// shows has to be in it: a size left out is removed, and one sent without its id is treated
  /// as new. See [NewProductVariant.id].
  Future<Either<Failure, Product>> update(int productId, NewProduct product);
}
