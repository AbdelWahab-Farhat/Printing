import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/models/design_version_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// A design version is two images or more (DESIGN-VERSION-IMAGES.md, owner 2026-11-20).
///
/// Arrange - Act - Assert throughout.
void main() {
  group('what a version may be made of', () {
    test('one image is refused with the sentence the server uses', () {
      // Act
      final refusal = DesignVersionRules.refusal(['front.png']);

      // Assert
      expect(refusal, 'أدخل صورتين على الأقل للتصميم');
    });

    test('two images go through, whatever the case of the extension', () {
      // Act
      final refusal = DesignVersionRules.refusal(['front.PNG', 'back.jpeg']);

      // Assert
      expect(refusal, isNull);
    });

    test('a PDF is not one of the images', () {
      // Act
      final refusal = DesignVersionRules.refusal(['front.png', 'print.pdf']);

      // Assert
      expect(refusal, 'صور التصميم يجب أن تكون JPG أو PNG أو WEBP');
    });

    test('more than six is refused', () {
      // Act
      final refusal = DesignVersionRules.refusal([
        for (var i = 0; i < 7; i++) 'face-$i.webp',
      ]);

      // Assert
      expect(refusal, 'لا تزيد صور التصميم على 6');
    });
  });

  group('the images of a version', () {
    Map<String, dynamic> payload({List<Map<String, dynamic>>? faces}) =>
        <String, dynamic>{
          'id': 31,
          'design_ticket_id': 7,
          'kind': 'submission',
          'kind_label': 'نسخة',
          'label': 'النسخة 1',
          'file_kind': 'image',
          'file_kind_label': 'صورة',
          'file_url': 'https://files.test/front.png',
          'version': 1,
          'faces': ?faces,
        };

    test('are read face by face, front first', () {
      // Arrange
      final json = payload(
        faces: [
          {'position': 1, 'file_url': 'https://files.test/front.png'},
          {'position': 2, 'file_url': 'https://files.test/back.png'},
        ],
      );

      // Act
      final version = DesignTicketFile.fromJson(json);

      // Assert
      expect(version.images.map((face) => face.position), [1, 2]);
      expect(version.images.last.fileUrl, 'https://files.test/back.png');
    });

    test(
      'fall back to the file itself on a version from before the change',
      () {
        // Act
        final version = DesignTicketFile.fromJson(payload());

        // Assert
        expect(version.images, hasLength(1));
        expect(version.images.single.fileUrl, 'https://files.test/front.png');
      },
    );
  });
}
