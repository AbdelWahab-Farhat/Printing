import 'dart:io';

import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/orders/models/receipt_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// The guard that makes copying the server's receipt limits into the app defensible.
///
/// [ReceiptRules] duplicates the `payment_receipts` numbers from `backend/config/media.php` so
/// a doomed upload is refused before it starts. A duplicated constant is a lie waiting to
/// happen — so this reads the PHP, exactly the way the design rules' contract test does.
/// Widen the list on the server and forget it here and the app keeps refusing files the API
/// would have taken.
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
      r"'max_kilobytes'\s*=>\s*\(int\)\s*env\('MEDIA_RECEIPT_MAX_KILOBYTES',\s*(\d+)\)",
    ).firstMatch(php);

    // Assert
    expect(
      match,
      isNotNull,
      reason: 'the regex matched nothing — did config/media.php change shape?',
    );
    expect(ReceiptRules.maxKilobytes, int.parse(match!.group(1)!));
  });

  test('the accepted formats are the ones the server accepts', () {
    // Arrange
    final php = config();
    if (php == null) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }

    // Act — the `mimes` list inside the payment_receipts block, which is the one whose Arabic
    // message names extensions to the user.
    final block = RegExp(
      r"'payment_receipts'\s*=>\s*\[(.*?)\n    \],",
      dotAll: true,
    ).firstMatch(php)?.group(1);
    final extensions = RegExp(r"'mimes'\s*=>\s*\[([^\]]*)\]").firstMatch(block ?? '')?.group(1);
    final backend = RegExp(
      "'([a-z]+)'",
    ).allMatches(extensions ?? '').map((match) => match.group(1)!).toSet();

    // Assert — and `svg` in either list is a stored-XSS hole, so it is named rather than left
    // to the set comparison to describe.
    expect(backend, isNotEmpty, reason: 'the regex matched nothing — did the block change shape?');
    expect(backend, isNot(contains('svg')));
    expect(ReceiptRules.extensions.toSet(), backend);
  });

  test('a file the server would refuse is refused here, in the same words', () {
    // Arrange
    const tooBig = PickedFile(path: '/tmp/huge.pdf', name: 'huge.pdf', sizeBytes: 11 * 1024 * 1024);
    const wrongKind = PickedFile(path: '/tmp/a.docx', name: 'a.docx', sizeBytes: 1024);
    const photographed = PickedFile(path: '/tmp/waseel.jpg', name: 'waseel.jpg', sizeBytes: 2048);

    // Act
    final tooBigAnswer = ReceiptRules.reject(tooBig);
    final wrongKindAnswer = ReceiptRules.reject(wrongKind);
    final photographedAnswer = ReceiptRules.reject(photographed);

    // Assert
    expect(tooBigAnswer, 'حجم الواصل يجب ألا يتجاوز 10 ميجابايت');
    expect(wrongKindAnswer, 'الواصل يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP');
    expect(photographedAnswer, isNull);
  });
}
