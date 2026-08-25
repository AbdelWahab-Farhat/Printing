import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/products/models/new_product.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';

/// Add a bag to the catalogue, or correct one already in it.
///
/// This is a use case that earns its keep, and the reason is one line of arithmetic the API
/// cannot forgive: **`٢٥` is what a Libyan keyboard produces, and every numeric rule on the
/// server is ASCII-only.** A dimension typed in Arabic-Indic digits does not fail validation —
/// `width_cm` is nullable, so it is accepted as absent and the size is stored without it. The
/// user is told nothing and finds out weeks later.
///
/// There are thirteen numeric places on this form (a minimum, plus a width, a height and up to
/// four prices per size), and converting them at the widget would mean thirteen chances to
/// forget. They are converted here instead, once, in the one file a test can reach without a
/// widget tree.
///
/// Money stays a `String` throughout — normalised, never parsed. Only the dimensions become
/// `int`s, because that is what the API's own type says they are.
class SaveProduct {
  const SaveProduct(this._repository);

  final ProductRepository _repository;

  /// [id] null adds; anything else corrects that product.
  ///
  /// **One use case for both, because it is one form.** The thirteen numeric places below are
  /// converted in exactly one place, and splitting create from update would have made it two —
  /// with one of them the copy that eventually gets fixed.
  ///
  /// [image] is required when adding and ignored when correcting: the server refuses a product
  /// with no photo, and a product being corrected already has one. Dart cannot express "required
  /// only when `id` is null" in a single signature, so the pairing is checked here rather than
  /// left to fail as a 422 the user has to read.
  Future<Either<Failure, Product>> call({
    int? id,
    required String name,
    String? description,
    List<String> features = const [],
    required int productCategoryId,

    /// «المادة» this product is cut from. Null omits the key entirely, which on an update means
    /// «اترك المادة كما هي» — the server offers no way to clear it, because clearing would
    /// detach every size from its shelf on that save. See [NewProduct.stockItemGroupId].
    int? stockItemGroupId,
    required String pricingUnit,
    required String pricingMode,
    required String minOrderQuantity,
    List<DraftVariant> variants = const [],
    PickedFile? image,
  }) {
    if (id == null && image == null) {
      // The form validates this before submitting, so reaching here is a bug rather than a user
      // mistake. Reported as a failure anyway: a crash in a Cubit takes the screen down, and the
      // sentence is the same one the server would have sent.
      return Future.value(
        const Left(Failure.server(message: 'صورة المنتج مطلوبة')),
      );
    }

    // Blank rows are what an "add a feature" button leaves behind when somebody changes their
    // mind, and `features.*` is `required|string` — an empty one is a 422 pointing at a field
    // the user believes they deleted.
    final kept = [
      for (final feature in features)
        if (feature.trim().isNotEmpty) feature.trim(),
    ];

    final product = NewProduct(
      // No slug: the server derives it from the name and the code it allocates. Sending one
      // is still allowed by the API for imports — see `GenerateProductSlug` — but a person
      // filling this form is not the right author of a unique Latin identifier.
      name: name.trim(),
      description: _blankToNull(description),
      // Omitted rather than sent empty: the rule is `nullable|array`, and `[]` says "this
      // product has no selling points" where absence says nothing at all.
      features: kept.isEmpty ? null : kept,
      productCategoryId: productCategoryId,
      stockItemGroupId: stockItemGroupId,
      pricingUnit: pricingUnit,
      pricingMode: pricingMode,
      minOrderQuantity: _number(minOrderQuantity),
      variants: [
        for (final variant in variants)
          NewProductVariant(
            // Carried straight through: a size that already exists must arrive with its id or
            // the server treats it as a new one and removes the old — see NewProductVariant.
            id: variant.id,
            // Round-tripped, never dropped. The server re-resolves every size's shelf on every
            // save, so a link the form was merely *showing* has to be sent back or it is lost —
            // see NewProductVariant.stockItemId, which is the whole argument.
            stockItemId: variant.stockItemId,
            label: variant.label.trim(),
            widthCm: _dimension(variant.widthCm),
            heightCm: _dimension(variant.heightCm),
            priceTiers: [
              for (final tier in variant.priceTiers)
                NewPriceTier(
                  minQuantity: _number(tier.minQuantity),
                  unitPrice: _number(tier.unitPrice),
                ),
            ],
          ),
      ],
    );

    return id == null
        ? _repository.create(product, image: image!)
        : _repository.update(id, product);
  }

  /// Arabic-Indic digits to ASCII, and a comma to a decimal point.
  ///
  /// `٬` and `,` are both decimal marks on the keyboards this app runs on, and `1,5` is a
  /// string the server reads as not-a-number.
  static String _number(String input) =>
      Validators.toWesternDigits(input.trim()).replaceAll(',', '.');

  static int? _dimension(String? input) {
    if (input == null || input.trim().isEmpty) return null;

    return int.tryParse(_number(input));
  }

  static String? _blankToNull(String? input) {
    final trimmed = input?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// One size as the form holds it: every number still text, because that is what was typed.
///
/// A plain class rather than a Freezed model — it never crosses a boundary, is never
/// serialised and never compared. It exists so [CreateProduct] takes one argument per size
/// instead of four parallel lists.
class DraftVariant {
  const DraftVariant({
    required this.label,
    this.id,
    this.stockItemId,
    this.widthCm,
    this.heightCm,
    this.priceTiers = const [],
  });

  /// Null for a size being added; the existing row's id when one is being corrected.
  final int? id;

  /// The shelf this size draws from, as the form found it or as somebody re-pointed it.
  ///
  /// **An `int` and not text, unlike every other value here**, because nobody types it: it comes
  /// from the product the form opened on, or from a picker that answered with a real row. The
  /// digits problem this class exists to hold back never arises for it.
  final int? stockItemId;

  final String label;
  final String? widthCm;
  final String? heightCm;
  final List<DraftPriceTier> priceTiers;
}

class DraftPriceTier {
  const DraftPriceTier({required this.minQuantity, required this.unitPrice});

  final String minQuantity;
  final String unitPrice;
}
