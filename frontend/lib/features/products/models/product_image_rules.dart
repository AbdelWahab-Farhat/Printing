import 'package:dayaa/core/files/picked_file.dart';

/// What the API will accept as a product photograph, checked before anything is sent.
///
/// **A copy of the server's rules, and knowingly so.** `backend/config/media.php` is the
/// authority and refuses everything this misses. The copy exists because the alternative is
/// pushing 6 MB over a Libyan mobile connection to be told the limit is 5 — a minute of
/// somebody's time and their data allowance, spent to learn something knowable instantly.
///
/// `test/features/products/product_image_rules_contract_test.dart` reads the PHP and fails when
/// the two drift apart, which is the only thing that makes duplicating a number defensible.
///
/// The twin of `DesignRules`, and deliberately not shared with it: a design is the customer's
/// artwork and may be a PDF, a product photo is the business's own marketing and may not. Two
/// uploads, two lists, and merging them would let a PDF through here to be refused at the door.
abstract final class ProductImageRules {
  /// `media.product_images.max_kilobytes`.
  static const int maxKilobytes = 5120;

  /// `media.product_images.mimes`.
  ///
  /// **`svg` is absent and must stay absent.** An SVG is an HTML document, and one served from
  /// our own origin is stored XSS — the same reason it is missing from the server's list.
  static const List<String> extensions = ['jpeg', 'jpg', 'png', 'webp'];

  /// `media.product_images.max_per_product`. The API refuses the next one after this many, and
  /// the screen says so before opening a picker rather than after an upload.
  static const int maxPerProduct = 5;

  /// Why this file cannot be uploaded, in the words the server would have used — or null when
  /// there is no reason.
  static String? reject(PickedFile file) {
    if (!extensions.contains(_extensionOf(file.name))) {
      // `jpeg` is left out of the sentence though it is accepted: it is the same format as
      // `jpg`, and naming both teaches nothing while making the line longer.
      return 'الصورة يجب أن تكون بصيغة JPG أو PNG أو WEBP';
    }

    if (file.sizeBytes > maxKilobytes * 1024) {
      return 'حجم الصورة يجب ألا يتجاوز ${maxKilobytes ~/ 1024} ميجابايت';
    }

    return null;
  }

  /// The extension, lowercased, with no dot. Empty for a name that has none.
  ///
  /// Read off the *name*, which is the one thing here that is the client's claim rather than a
  /// fact — the server sniffs the bytes with `image` on top of its mime list, and that is the
  /// reason this is safe. It only decides whether it is worth starting the upload.
  static String _extensionOf(String filename) {
    final dot = filename.lastIndexOf('.');

    return dot == -1 ? '' : filename.substring(dot + 1).toLowerCase();
  }
}
