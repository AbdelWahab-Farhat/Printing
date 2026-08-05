import 'package:file_picker/file_picker.dart';
// `image_picker` still exports a deprecated class of its own called `PickedFile`. Hidden rather
// than prefixed: ours is the one every other file in the app means, and an import prefix here
// would be the only place in the codebase where it needed one.
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:printing/core/files/attachment_picker.dart';
import 'package:printing/core/files/picked_file.dart';

/// Fulfils [AttachmentPicker] with the two packages that actually open the pickers.
///
/// This is the only file in the app that imports either of them, which is what lets the sheet,
/// the Cubit and the screen be tested without a platform channel.
///
/// **No `try`/`catch` here, on purpose.** A picker that throws is a broken plugin registration
/// or a missing `Info.plist` key — a build fault, not a runtime condition — and swallowing it
/// would ship a button that silently does nothing. Cancelling, which *is* an ordinary ending,
/// is an empty list rather than an exception.
class AttachmentPickerImpl implements AttachmentPicker {
  AttachmentPickerImpl({ImagePicker? images}) : _images = images ?? ImagePicker();

  final ImagePicker _images;

  @override
  Future<List<PickedFile>> pick(AttachmentSource source) => switch (source) {
    AttachmentSource.documents => _documents(),
    AttachmentSource.photos => _photos(),
    AttachmentSource.camera => _camera(),
  };

  /// The system document browser, filtered to the formats the API accepts.
  ///
  /// The filter is a courtesy — the server sniffs the bytes and refuses anything else — but it
  /// stops somebody walking through their whole Files app to pick a `.docx` that was never
  /// going to be accepted.
  Future<List<PickedFile>> _documents() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      // The bytes are never held in memory: a 25 MB design multiplied by a multi-select is how
      // an app gets killed for memory on a mid-range phone. Dio streams from the path instead.
      withData: false,
    );

    if (result == null) return const [];

    return [
      for (final file in result.files)
        // Null on web only, where this app does not run — but a null path would be an upload
        // of nothing, so it is dropped rather than forced.
        if (file.path case final path?)
          PickedFile(path: path, name: file.name, sizeBytes: file.size),
    ];
  }

  /// The photo library. Where a design sent over WhatsApp actually is.
  Future<List<PickedFile>> _photos() async {
    final files = await _images.pickMultiImage();

    return [for (final file in files) await _fromXFile(file)];
  }

  /// Taken now — for the customer who walks in with a printed sample.
  Future<List<PickedFile>> _camera() async {
    final file = await _images.pickImage(source: ImageSource.camera);

    // Backing out of the camera is not a failure.
    return file == null ? const [] : [await _fromXFile(file)];
  }

  /// `XFile` knows its size only by asking the file system, which is why this is async.
  static Future<PickedFile> _fromXFile(XFile file) async =>
      PickedFile(path: file.path, name: file.name, sizeBytes: await file.length());
}
