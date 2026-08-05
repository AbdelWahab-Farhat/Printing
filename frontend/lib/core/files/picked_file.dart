import 'package:flutter/foundation.dart';

/// A file the user chose, whichever of the three places they chose it from.
///
/// One type for all of them on purpose: the document browser, the photo library and the camera
/// each hand back a different object, and without this every screen that uploads would have to
/// know which. Above [AttachmentPicker] there is only ever a path, a name and a size.
@immutable
class PickedFile {
  const PickedFile({required this.path, required this.name, required this.sizeBytes});

  /// Where the file is on this device.
  ///
  /// **A temporary location, more often than not.** iOS hands back a copy in the app's cache
  /// for anything taken from the photo library or the camera, and the system is free to sweep
  /// it. So it is read once, straight into the upload, and never stored to be opened later.
  final String path;

  /// What to call it on screen, and what the server records as `original_filename`.
  final String name;

  /// Known before the upload starts, which is the only reason a progress bar can show a
  /// fraction rather than a spinner.
  final int sizeBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickedFile &&
          other.path == path &&
          other.name == name &&
          other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(path, name, sizeBytes);

  @override
  String toString() => 'PickedFile($name, $sizeBytes bytes)';
}
