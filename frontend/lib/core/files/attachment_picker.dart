import 'package:printing/core/files/picked_file.dart';

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
  /// What the user chose, or an empty list if they backed out.
  ///
  /// **Cancelling is not a failure.** It returns empty rather than throwing or answering a
  /// `Failure`, because a person changing their mind is the expected ending of this call and
  /// nothing should be reported to them about it.
  Future<List<PickedFile>> pick(AttachmentSource source);
}
