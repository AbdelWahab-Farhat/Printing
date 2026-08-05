import 'package:printing/core/files/picked_file.dart';

/// What the API will accept as a design, checked before anything is sent.
///
/// **A copy of the server's rules, and knowingly so.** `backend/config/media.php` is the
/// authority and refuses everything this misses. The copy exists because the alternative is
/// pushing 25 MB over a Libyan mobile connection to be told the file is 26 — a minute of
/// somebody's time and their data allowance, spent to learn something knowable instantly.
///
/// `test/features/customers/design_rules_contract_test.dart` reads the PHP and fails when the
/// two drift apart, which is the only thing that makes duplicating a number defensible.
abstract final class DesignRules {
  /// `media.customer_designs.max_kilobytes`.
  static const int maxKilobytes = 25600;

  /// `media.customer_designs.mimes`.
  ///
  /// **`svg` is absent and must stay absent.** An SVG is an HTML document, and one served from
  /// our own origin is stored XSS — the same reason it is missing from the server's list.
  static const List<String> extensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];

  /// `media.customer_designs.max_per_customer`. The API's own cap, and the reason its list
  /// endpoint does not page.
  static const int maxPerCustomer = 50;

  /// Why this file cannot be uploaded, in the words the server would have used — or null when
  /// there is no reason.
  static String? reject(PickedFile file) {
    if (!extensions.contains(_extensionOf(file.name))) {
      return 'الملف يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP';
    }

    if (file.sizeBytes > maxKilobytes * 1024) {
      return 'حجم الملف يجب ألا يتجاوز ${maxKilobytes ~/ 1024} ميجابايت';
    }

    return null;
  }

  /// The extension, lowercased, with no dot. Empty for a name that has none.
  ///
  /// Read off the *name*, which is the one thing here that is the client's claim rather than a
  /// fact — the server sniffs the bytes and is the reason that is safe. This only decides
  /// whether it is worth starting the upload.
  static String _extensionOf(String filename) {
    final dot = filename.lastIndexOf('.');

    return dot == -1 ? '' : filename.substring(dot + 1).toLowerCase();
  }
}
