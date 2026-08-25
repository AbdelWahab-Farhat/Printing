import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/products/models/new_product.dart';
import 'package:dayaa/features/products/models/price_quote.dart';
import 'package:dayaa/features/products/models/product.dart';

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
  ///
  /// **The same replacement re-resolves every size's shelf**, so a size sent without its
  /// `stock_item_id` does not keep the one it had — see [NewProductVariant.stockItemId]. The
  /// product's own material is the exception: leaving it out keeps it.
  ///
  /// There is no separate call for what the warehouse counts a product in any more.
  /// `PATCH /products/{id}/stock-unit` is gone from the API — a pile is not one product's, so
  /// the unit belongs to the shelf and moves through `PATCH /stock-items/{id}/unit`, which
  /// **empties** every warehouse holding it rather than relabelling the figures.
  Future<Either<Failure, Product>> update(int productId, NewProduct product);

  /// Adds one photograph to a product that already exists.
  ///
  /// **Separate from [create], which carries the first one.** A product is born with a picture;
  /// this is every picture after that, and the server caps how many — see
  /// `ProductImageRules.maxPerProduct`, which the screen checks before opening a picker so the
  /// refusal does not cost an upload.
  ///
  /// `is_primary` is never sent: a photo arrives as an ordinary one, and promoting it is a
  /// separate decision the user takes afterwards with [makeImagePrimary].
  Future<Either<Failure, ProductImage>> uploadImage(
    int productId, {
    required PickedFile image,
    void Function(int sent, int total)? onProgress,
  });

  /// Makes one of a product's photographs the one every other screen draws.
  ///
  /// **Promotion only — there is no demotion.** A product needs exactly one primary, so the way
  /// to stop this being it is to promote another; the API refuses `is_primary: false` outright.
  ///
  /// Answers with the promoted image alone, which is why the caller reloads: the photograph that
  /// *lost* the badge is not in this response, and drawing two primaries is worse than a second
  /// request.
  Future<Either<Failure, ProductImage>> makeImagePrimary(int productId, int imageId);

  /// Removes one photograph, and its file.
  ///
  /// **Refused by the server when it is the last one**, so a product is never left without a
  /// picture — the same rule that makes a photo mandatory at creation, enforced at the other end
  /// of the life cycle. Deleting the primary promotes the next in line, which is the second
  /// reason the caller reloads rather than striking a row out of a list it holds.
  ///
  /// The stored file is deleted for real, unlike a customer's design: there is no `deleted_at`
  /// on object storage, so this cannot be undone from here or anywhere else.
  Future<Either<Failure, String>> deleteImage(int productId, int imageId);
}
