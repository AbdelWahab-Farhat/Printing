import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer_design.dart';
import 'package:printing/features/customers/repositories/customer_design_repository.dart';

/// Fetches a design and writes it somewhere the phone can hand to its own share sheet.
///
/// **The temp directory, not Documents.** The file is a courier, not a copy: it exists for the
/// two seconds between «تحميل» and the OS sheet where the person picks Photos, Files or
/// WhatsApp. Keeping our own second library of every design anybody ever looked at would fill
/// the phone with duplicates of files the server already holds.
///
/// The filename is what the person will see in that sheet and in whatever they save it to, so
/// it is built from the design's label rather than from the id — «شعار المخبز.png» is findable
/// afterwards and `design-41` is not.
class SaveDesignToDevice {
  const SaveDesignToDevice(this._repository);

  final CustomerDesignRepository _repository;

  /// The written file's path, ready to be shared.
  Future<Either<Failure, String>> call(CustomerDesign design) async {
    final url = design.fileUrl;

    if (url == null || url.isEmpty) {
      // Not a network failure and not our bug: the row simply came without a link, which
      // happens on an endpoint that did not load it.
      return const Left(Failure.unexpected(message: 'لا يوجد رابط لهذا الملف'));
    }

    final result = await _repository.fileBytes(url);

    return result.fold<Future<Either<Failure, String>>>(
      (failure) async => Left(failure),
      (bytes) async {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/${fileNameFor(design)}');
        await file.writeAsBytes(bytes);

        return Right(file.path);
      },
    );
  }

  /// `شعار المخبز.png` — the label, made safe for a filesystem, with the right extension.
  ///
  /// Public and static because it is pure and it is the one rule about what a saved design is
  /// called; a test asserts on it directly rather than through a file write.
  static String fileNameFor(CustomerDesign design) {
    // `/` and `\` end a path segment, and a name that is only punctuation leaves an empty
    // filename — both are how a write fails with an error nobody can act on.
    final safe = design.label
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '-')
        .trim();

    final base = safe.isEmpty ? 'تصميم-${design.id}' : safe;
    final extension = _extensionFor(design);

    return base.toLowerCase().endsWith(extension) ? base : '$base$extension';
  }

  /// The original file's extension when the server sent one, then the MIME type, then the kind.
  ///
  /// Order matters: the extension the customer's own file had is what the printer expects to
  /// receive, and guessing `.png` for a `.jpg` produces a file some tools refuse to open.
  static String _extensionFor(CustomerDesign design) {
    final original = design.originalFilename;

    if (original != null && original.contains('.')) {
      final extension = original.substring(original.lastIndexOf('.'));
      if (extension.length <= 6) return extension.toLowerCase();
    }

    return switch (design.mimeType) {
      'image/png' => '.png',
      'image/jpeg' || 'image/jpg' => '.jpg',
      'image/webp' => '.webp',
      'application/pdf' => '.pdf',
      _ => design.kind == DesignKind.pdf ? '.pdf' : '.png',
    };
  }
}
