import 'dart:io';

import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/products/models/product_image_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// The guard that makes copying the server's limits into the app defensible.
///
/// [ProductImageRules] duplicates three numbers from `backend/config/media.php` so a photograph
/// the API would refuse is refused before a byte leaves the phone. A duplicated constant is a
/// lie waiting to happen — so this reads the PHP. Raise the cap on the server and forget it
/// here and the app keeps refusing uploads the API would have taken.
///
/// The twin of `design_rules_contract_test.dart`, deliberately: same shape, same skip, same
/// reason to exist.
///
/// Arrange - Act - Assert throughout.
void main() {
  final source = File('../backend/config/media.php');

  String? config() => source.existsSync() ? source.readAsStringSync() : null;

  /// The `product_images` block alone. The file holds three blocks with identically named keys
  /// — `max_kilobytes` appears in the designs block too — so a regex over the whole file would
  /// happily assert the app against the wrong limit.
  String? productImagesBlock(String php) =>
      RegExp(r"'product_images'\s*=>\s*\[(.*?)\n    \],", dotAll: true).firstMatch(php)?.group(1);

  test('the size limit is the one the server enforces', () {
    // Arrange
    final php = config();
    if (php == null) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }

    // Act
    final match = RegExp(
      r"'max_kilobytes'\s*=>\s*\(int\)\s*env\('MEDIA_MAX_KILOBYTES',\s*(\d+)\)",
    ).firstMatch(productImagesBlock(php) ?? '');

    // Assert
    expect(
      match,
      isNotNull,
      reason: 'the regex matched nothing — did the product_images block change shape?',
    );
    expect(ProductImageRules.maxKilobytes, int.parse(match!.group(1)!));
  });

  test('the accepted formats are the ones the server accepts', () {
    // Arrange
    final php = config();
    if (php == null) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }

    // Act
    final extensions = RegExp(
      r"'mimes'\s*=>\s*\[([^\]]*)\]",
    ).firstMatch(productImagesBlock(php) ?? '')?.group(1);
    final backend = RegExp(
      "'([a-z]+)'",
    ).allMatches(extensions ?? '').map((match) => match.group(1)!).toSet();

    // Assert — `svg` in either list is a stored-XSS hole, so it is named rather than left to
    // the set comparison to describe.
    expect(backend, isNotEmpty, reason: 'the regex matched nothing');
    expect(backend, isNot(contains('svg')));
    expect(ProductImageRules.extensions.toSet(), backend);
  });

  test('the per-product cap is the one the server applies', () {
    // Arrange — the app refuses the sixth photo before opening the picker, and the API refuses
    // it after the bytes arrive. Both must mean the same number or the courtesy becomes a lie.
    final php = config();
    if (php == null) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }

    // Act
    final match = RegExp(
      r"'max_per_product'\s*=>\s*\(int\)\s*env\('MEDIA_MAX_IMAGES_PER_PRODUCT',\s*(\d+)\)",
    ).firstMatch(productImagesBlock(php) ?? '');

    // Assert
    expect(match, isNotNull, reason: 'the regex matched nothing');
    expect(ProductImageRules.maxPerProduct, int.parse(match!.group(1)!));
  });

  test('a file the server would refuse is refused here, in the same words', () {
    // Arrange
    const tooBig = PickedFile(path: '/tmp/huge.jpg', name: 'huge.jpg', sizeBytes: 6 * 1024 * 1024);
    const wrongKind = PickedFile(path: '/tmp/a.pdf', name: 'a.pdf', sizeBytes: 1024);

    // Act & Assert — a PDF is a design, not a product photo: the two uploads accept different
    // things, and this is the one that does not take documents.
    expect(ProductImageRules.reject(tooBig), 'حجم الصورة يجب ألا يتجاوز 5 ميجابايت');
    expect(ProductImageRules.reject(wrongKind), 'الصورة يجب أن تكون بصيغة JPG أو PNG أو WEBP');
  });

  test('an acceptable photo has nothing said about it', () {
    // Arrange
    const shouting = PickedFile(path: '/tmp/IMG_0042.JPG', name: 'IMG_0042.JPG', sizeBytes: 2048);
    const exactlyAtTheLimit = PickedFile(
      path: '/tmp/edge.png',
      name: 'edge.png',
      sizeBytes: ProductImageRules.maxKilobytes * 1024,
    );

    // Act & Assert — the limit is inclusive on the server (`max:5120` passes at 5120), so it
    // must be inclusive here too, or the app refuses a photo the API would have taken.
    expect(ProductImageRules.reject(shouting), isNull);
    expect(ProductImageRules.reject(exactlyAtTheLimit), isNull);
  });

  test('a file with no extension at all is refused rather than sent', () {
    // Arrange — iOS hands back names like this for something shared out of another app.
    const nameless = PickedFile(path: '/tmp/tmp1234', name: 'tmp1234', sizeBytes: 1024);

    // Act & Assert
    expect(ProductImageRules.reject(nameless), isNotNull);
  });
}
