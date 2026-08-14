import 'dart:io';

import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/customers/models/design_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// The guard that makes copying the server's limits into the app defensible.
///
/// [DesignRules] duplicates three numbers from `backend/config/media.php` so a doomed 25 MB
/// upload is refused before it starts. A duplicated constant is a lie waiting to happen — so
/// this reads the PHP. Raise the limit on the server and forget it here and the app keeps
/// refusing files the API would have taken.
///
/// Skips rather than fails when the backend is not checked out beside this, so a frontend-only
/// clone still goes green.
///
/// Arrange - Act - Assert throughout.
void main() {
  final source = File('../backend/config/media.php');

  String? config() => source.existsSync() ? source.readAsStringSync() : null;

  test('the size limit is the one the server enforces', () {
    // Arrange
    final php = config();
    if (php == null) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }

    // Act
    final match = RegExp(
      r"'max_kilobytes'\s*=>\s*\(int\)\s*env\('MEDIA_DESIGN_MAX_KILOBYTES',\s*(\d+)\)",
    ).firstMatch(php);

    // Assert
    expect(
      match,
      isNotNull,
      reason: 'the regex matched nothing — did config/media.php change shape?',
    );
    expect(DesignRules.maxKilobytes, int.parse(match!.group(1)!));
  });

  test('the accepted formats are the ones the server accepts', () {
    // Arrange
    final php = config();
    if (php == null) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }

    // Act — the `mimes` list inside the customer_designs block, which is the one whose Arabic
    // message names extensions to the user.
    final block = RegExp(
      r"'customer_designs'\s*=>\s*\[(.*?)\n    \],",
      dotAll: true,
    ).firstMatch(php)?.group(1);
    final extensions = RegExp(r"'mimes'\s*=>\s*\[([^\]]*)\]").firstMatch(block ?? '')?.group(1);
    final backend = RegExp(
      "'([a-z]+)'",
    ).allMatches(extensions ?? '').map((match) => match.group(1)!).toSet();

    // Assert — and `svg` in either list is a stored-XSS hole, so it is named rather than left
    // to the set comparison to describe.
    expect(
      backend,
      isNotEmpty,
      reason: 'the regex matched nothing — did the block change shape?',
    );
    expect(backend, isNot(contains('svg')));
    expect(DesignRules.extensions.toSet(), backend);
  });

  test('the per-customer cap is the one the server applies', () {
    // Arrange — this is why the list endpoint does not page, so the app agreeing with it is
    // what keeps a plain list honest.
    final php = config();
    if (php == null) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }

    // Act
    final match = RegExp(
      r"'max_per_customer'\s*=>\s*\(int\)\s*env\('MEDIA_DESIGNS_MAX_PER_CUSTOMER',\s*(\d+)\)",
    ).firstMatch(php);

    // Assert
    expect(match, isNotNull, reason: 'the regex matched nothing');
    expect(DesignRules.maxPerCustomer, int.parse(match!.group(1)!));
  });

  test('a file the server would refuse is refused here, in the same words', () {
    // Arrange
    const tooBig = PickedFile(
      path: '/tmp/huge.pdf',
      name: 'huge.pdf',
      sizeBytes: 26 * 1024 * 1024,
    );
    const wrongKind = PickedFile(path: '/tmp/a.docx', name: 'a.docx', sizeBytes: 1024);

    // Act & Assert
    expect(DesignRules.reject(tooBig), 'حجم الملف يجب ألا يتجاوز 25 ميجابايت');
    expect(DesignRules.reject(wrongKind), 'الملف يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP');
  });

  test('an acceptable file has nothing said about it', () {
    // Arrange — and the extension is read case-insensitively, because a photo off a camera
    // roll is as likely to be `.JPG` as `.jpg`.
    const shouting = PickedFile(
      path: '/tmp/IMG_0042.JPG',
      name: 'IMG_0042.JPG',
      sizeBytes: 2048,
    );
    const exactlyAtTheLimit = PickedFile(
      path: '/tmp/edge.pdf',
      name: 'edge.pdf',
      sizeBytes: DesignRules.maxKilobytes * 1024,
    );

    // Act & Assert — the limit is inclusive on the server (`max:25600` passes at 25600), so it
    // must be inclusive here too, or the app refuses a file the API would have taken.
    expect(DesignRules.reject(shouting), isNull);
    expect(DesignRules.reject(exactlyAtTheLimit), isNull);
  });

  test('a file with no extension at all is refused rather than sent', () {
    // Arrange — iOS hands back names like this for something shared out of another app.
    const nameless = PickedFile(path: '/tmp/tmp1234', name: 'tmp1234', sizeBytes: 1024);

    // Act & Assert
    expect(DesignRules.reject(nameless), isNotNull);
  });
}
