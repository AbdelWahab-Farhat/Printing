import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seam between `CustomerDesignResource` and this app.
///
/// Every key asserted here is one the backend sends today — see
/// `backend/app/Application/Api/V1/Resources/CustomerDesignResource.php`. A rename over there
/// fails here rather than showing up as an empty tile on somebody's phone.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('parses an uploaded image, keys and all', () {
    // Arrange — the `data` block of a 201 from POST /customers/{id}/designs.
    final json = <String, dynamic>{
      'id': 12,
      'customer_id': 7,
      'label': 'شعار المخبز',
      'notes': 'بالألوان الأصلية',
      'kind': 'image',
      'kind_label': 'صورة',
      'mime_type': 'image/png',
      'original_filename': 'logo.png',
      'size_bytes': 245760,
      'width_px': 1200,
      'height_px': 800,
      'file_url': 'https://cdn.example.com/designs/logo.png?signature=abc',
      'preview_url': null,
      'created_at': '2026-08-02T09:15:00+00:00',
    };

    // Act
    final design = CustomerDesign.fromJson(json);

    // Assert
    expect(design.id, 12);
    expect(design.customerId, 7);
    expect(design.label, 'شعار المخبز');
    expect(design.notes, 'بالألوان الأصلية');
    expect(design.kind, DesignKind.image);
    expect(design.kindLabel, 'صورة');
    expect(design.mimeType, 'image/png');
    expect(design.originalFilename, 'logo.png');
    expect(design.sizeBytes, 245760);
    expect(design.widthPx, 1200);
    expect(design.heightPx, 800);
    expect(design.fileUrl, 'https://cdn.example.com/designs/logo.png?signature=abc');
    expect(design.createdAt, DateTime.parse('2026-08-02T09:15:00+00:00'));
  });

  test('a PDF carries no dimensions, and says so with null rather than zero', () {
    // Arrange — a PDF really does come back with `width_px` and `height_px` unset.
    final json = <String, dynamic>{
      'id': 13,
      'customer_id': 7,
      'label': 'التصميم النهائي.pdf',
      'notes': null,
      'kind': 'pdf',
      'kind_label': 'PDF',
      'mime_type': 'application/pdf',
      'original_filename': 'التصميم النهائي.pdf',
      'size_bytes': 1048576,
      'width_px': null,
      'height_px': null,
      'file_url': 'https://cdn.example.com/designs/final.pdf',
      'preview_url': null,
      'created_at': '2026-08-02T09:20:00+00:00',
    };

    // Act
    final design = CustomerDesign.fromJson(json);

    // Assert — a 0×0 would be drawn as a real size by anything that reads it.
    expect(design.kind, DesignKind.pdf);
    expect(design.isImage, isFalse);
    expect(design.widthPx, isNull);
    expect(design.dimensionsLabel, isNull);
  });

  test('a kind this build has never heard of is inert, not a crash', () {
    // Arrange — the day the API learns to accept, say, an AI file, an app already on a phone
    // has to keep listing that customer's designs rather than failing to parse the page.
    final json = <String, dynamic>{
      'id': 14,
      'customer_id': 7,
      'label': 'مخطط',
      'kind': 'vector',
      'kind_label': 'ملف مُتّجه',
      'file_url': 'https://cdn.example.com/designs/plan.ai',
    };

    // Act
    final design = CustomerDesign.fromJson(json);

    // Assert — unknown, so nothing tries to draw it inline, and the server's own Arabic name
    // is still what the tile shows.
    expect(design.kind, DesignKind.unknown);
    expect(design.isImage, isFalse);
    expect(design.thumbnailUrl, isNull);
    expect(design.kindLabel, 'ملف مُتّجه');
  });

  test('an image is its own thumbnail until the server renders one', () {
    // Arrange — `preview_url` is reserved on the backend and always null today.
    const image = CustomerDesign(
      id: 1,
      customerId: 7,
      label: 'شعار',
      kind: DesignKind.image,
      kindLabel: 'صورة',
      fileUrl: 'https://cdn.example.com/a.png',
    );
    const pdf = CustomerDesign(
      id: 2,
      customerId: 7,
      label: 'ملف',
      kind: DesignKind.pdf,
      kindLabel: 'PDF',
      fileUrl: 'https://cdn.example.com/b.pdf',
    );

    // Act & Assert — and a PDF has nothing to draw, which is what puts a glyph in its tile
    // instead of a broken image.
    expect(image.thumbnailUrl, 'https://cdn.example.com/a.png');
    expect(pdf.thumbnailUrl, isNull);
  });

  test('a rendered preview wins over the file itself', () {
    // Arrange — the day the backend fills `preview_url` for PDFs, the grid must stop showing a
    // glyph without an app release. That is the entire reason the key exists now.
    const design = CustomerDesign(
      id: 3,
      customerId: 7,
      label: 'ملف',
      kind: DesignKind.pdf,
      kindLabel: 'PDF',
      fileUrl: 'https://cdn.example.com/b.pdf',
      previewUrl: 'https://cdn.example.com/b-page-1.jpg',
    );

    // Act & Assert
    expect(design.thumbnailUrl, 'https://cdn.example.com/b-page-1.jpg');
  });

  test('a size is read as a size, at whatever scale it lands', () {
    // Arrange
    CustomerDesign withSize(int? bytes) => CustomerDesign(
      id: 1,
      customerId: 7,
      label: 'ملف',
      kind: DesignKind.pdf,
      kindLabel: 'PDF',
      sizeBytes: bytes,
    );

    // Act & Assert — bytes for something tiny, and never «0.2 ميجابايت» for a 240 KB logo.
    expect(withSize(800).sizeLabel, '800 بايت');
    expect(withSize(245760).sizeLabel, '240 كيلوبايت');
    expect(withSize(2621440).sizeLabel, '2.5 ميجابايت');
    // A decimal that lands on zero is dropped: «1.0 ميجابايت» reads as a measurement claiming
    // a precision it does not have.
    expect(withSize(1048576).sizeLabel, '1 ميجابايت');
    // Absent, not zero: the server may not have measured it.
    expect(withSize(null).sizeLabel, isNull);
  });

  test('dimensions read left to right, as numbers do', () {
    // Arrange
    const design = CustomerDesign(
      id: 1,
      customerId: 7,
      label: 'شعار',
      kind: DesignKind.image,
      kindLabel: 'صورة',
      widthPx: 1200,
      heightPx: 800,
    );

    // Act & Assert
    expect(design.dimensionsLabel, '1200 × 800');
  });

  test('half a pair of dimensions is not a size', () {
    // Arrange — a width with no height is a measurement that failed, and «1200 × » is worse
    // than saying nothing.
    const design = CustomerDesign(
      id: 1,
      customerId: 7,
      label: 'شعار',
      kind: DesignKind.image,
      kindLabel: 'صورة',
      widthPx: 1200,
    );

    // Act & Assert
    expect(design.dimensionsLabel, isNull);
  });
}
