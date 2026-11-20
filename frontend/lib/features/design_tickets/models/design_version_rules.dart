/// What a design version may be made of (DESIGN-VERSION-IMAGES.md, owner 2026-11-20).
///
/// **A mirror of `config('media.design_tickets.version_*')`.** The server refuses anything else
/// with a sentence of its own; checking here first only saves the designer an upload that was
/// going to be turned away.
abstract final class DesignVersionRules {
  /// Two images at least: the order card shows every image of the approved version.
  static const int minImages = 2;

  /// Keeps the card's cover strip to two rows.
  static const int maxImages = 6;

  /// Images only — a PDF cannot be drawn on the card. A print PDF goes in the ticket chat.
  static const List<String> extensions = ['jpg', 'jpeg', 'png', 'webp'];

  static const String tooFew = 'أدخل صورتين على الأقل للتصميم';

  static const String tooMany = 'لا تزيد صور التصميم على $maxImages';

  static const String notAnImage = 'صور التصميم يجب أن تكون JPG أو PNG أو WEBP';

  /// The server refuses the same image twice in one version; said here as it is added.
  static const String duplicate = 'هذه الصورة مضافة من قبل';

  /// Whether [name] ends in one of [extensions], whatever its case.
  static bool isImage(String name) {
    final dot = name.lastIndexOf('.');

    return dot >= 0 && extensions.contains(name.substring(dot + 1).toLowerCase());
  }

  /// Null when [names] may go up as one version, else the sentence saying why not.
  static String? refusal(List<String> names) {
    if (names.length < minImages) return tooFew;
    if (names.length > maxImages) return tooMany;

    return names.every(isImage) ? null : notAnImage;
  }
}
