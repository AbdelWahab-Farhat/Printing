import 'package:dayaa/core/files/picked_file.dart';

/// What the API will accept as a receipt (الواصل), checked before anything is sent.
///
/// **A copy of the server's rules, and knowingly so.** `backend/config/media.php` is the
/// authority (`payment_receipts`) and refuses everything this misses. The copy exists for the
/// same reason the design rules keep theirs: pushing a doomed file over a Libyan mobile
/// connection to be told it is the wrong kind is a person's time and data allowance, spent to
/// learn something knowable instantly.
///
/// `test/features/orders/receipt_rules_contract_test.dart` reads the PHP and fails when the
/// two drift apart, which is the only thing that makes duplicating the list defensible.
abstract final class ReceiptRules {
  /// `media.payment_receipts.max_kilobytes`.
  static const int maxKilobytes = 10240;

  /// `media.payment_receipts.mimes`.
  ///
  /// Images joined PDF on 2026-08-22: the receipt that actually arrives is a phone photograph
  /// or a banking-app screenshot, not the bank's own document. **`svg` is absent and must stay
  /// absent** — an SVG is an HTML document, and one served from our own origin is stored XSS.
  static const List<String> extensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];

  /// Why this file cannot be attached, in the words the server would have used — or null when
  /// there is no reason.
  static String? reject(PickedFile file) {
    if (!extensions.contains(_extensionOf(file.name))) {
      return 'الواصل يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP';
    }

    if (file.sizeBytes > maxKilobytes * 1024) {
      return 'حجم الواصل يجب ألا يتجاوز ${maxKilobytes ~/ 1024} ميجابايت';
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
