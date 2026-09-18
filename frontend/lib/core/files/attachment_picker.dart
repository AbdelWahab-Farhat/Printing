import 'package:dayaa/core/files/picked_file.dart';

/// Where a file is coming from.
///
/// Three, not one, and the reason is the phones this runs on. A design arrives either as a PDF
/// in an email — which lands in the document browser — or as an image over WhatsApp, which on
/// iOS lands in the photo library, a place the Files app cannot see at all. Offering only a
/// document browser would make the commonest case impossible.
enum AttachmentSource {
  /// The system's document browser — Files on iOS, the storage picker on Android.
  documents,

  /// The photo library.
  photos,

  /// Taken now. For the customer who walks in with a printed sample.
  camera,
}

/// Getting files off the device, without any screen knowing which package does it.
///
/// An interface rather than a call to `FilePicker.platform` at the call site, and the reason is
/// testing: both packages answer through a platform channel that does not exist under
/// `flutter_test`, so a widget test of an upload flow would hang or throw on the pick. A fake
/// implementation of this hands back two paths and the rest of the flow is exercised for real.
abstract interface class AttachmentPicker {
  /// What every caller took before any of them said otherwise — the customer design library's
  /// list, which is also the receipts'.
  static const List<String> defaultExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];

  /// What the user chose, or an empty list if they backed out.
  ///
  /// **Cancelling is not a failure.** It returns empty rather than throwing or answering a
  /// `Failure`, because a person changing their mind is the expected ending of this call and
  /// nothing should be reported to them about it.
  ///
  /// [extensions] filters the document browser, and **the caller owns it** because the three
  /// endpoints behind this do not agree: a design ticket's brief takes more formats than the
  /// customer's design library, whose list a contract test holds to the server's to the letter.
  /// One shared list here meant widening it for one caller silently widened it for all three.
  /// The filter is a courtesy in any case — the server sniffs the bytes and refuses the rest.
  Future<List<PickedFile>> pick(
    AttachmentSource source, {
    List<String> extensions = defaultExtensions,
  });
}
