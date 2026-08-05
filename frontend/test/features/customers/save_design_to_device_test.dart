import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer_design.dart';
import 'package:printing/features/customers/repositories/customer_design_repository.dart';
import 'package:printing/features/customers/usecases/save_design_to_device.dart';

/// «تحميل» — what the file is called when it lands on the phone, and what happens when it
/// cannot be fetched at all.
///
/// The write itself is not tested here: it is `File.writeAsBytes` into a directory the OS
/// chooses, and a test that mocks `path_provider` to assert Dart can write a file proves
/// nothing about this app. What *is* ours is the name and the refusals.
///
/// Arrange - Act - Assert throughout.
class _MockDesignRepository extends Mock implements CustomerDesignRepository {}

void main() {
  late _MockDesignRepository repository;
  late SaveDesignToDevice save;

  CustomerDesign design({
    String label = 'شعار المخبز',
    String? fileUrl = 'https://files.example/design.png?signature=abc',
    String? originalFilename,
    String? mimeType,
    DesignKind kind = DesignKind.image,
  }) {
    return CustomerDesign(
      id: 41,
      customerId: 3,
      label: label,
      kind: kind,
      kindLabel: kind == DesignKind.pdf ? 'ملف PDF' : 'صورة',
      originalFilename: originalFilename,
      mimeType: mimeType,
      fileUrl: fileUrl,
    );
  }

  setUp(() {
    repository = _MockDesignRepository();
    save = SaveDesignToDevice(repository);
  });

  group('what the saved file is called', () {
    test('the label is the name, so it is findable afterwards', () {
      // Arrange
      final subject = design(originalFilename: 'IMG_2231.png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert — «design-41.png» is a name nobody recognises in a Files app a week later.
      expect(name, 'شعار المخبز.png');
    });

    test('the original extension wins over the mime type', () {
      // Arrange — the printer expects the file the customer sent, and .jpg saved as .png is a
      // file some tools refuse to open.
      final subject = design(originalFilename: 'logo.JPG', mimeType: 'image/png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert
      expect(name, 'شعار المخبز.jpg');
    });

    test('a PDF keeps its own extension', () {
      // Arrange
      final subject = design(kind: DesignKind.pdf, mimeType: 'application/pdf');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert
      expect(name, 'شعار المخبز.pdf');
    });

    test('a label that is already the filename is not given a second extension', () {
      // Arrange
      final subject = design(label: 'شعار.png', mimeType: 'image/png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert
      expect(name, 'شعار.png');
    });

    test('a slash in a label does not become a directory', () {
      // Arrange — «شعار 2024/2025» is a name somebody will type, and a path separator in it is
      // a write that fails with an error nobody can act on.
      final subject = design(label: 'شعار 2024/2025', mimeType: 'image/png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert
      expect(name, 'شعار 2024-2025.png');
      expect(name.contains('/'), isFalse);
    });

    test('a label of nothing but punctuation still yields a filename', () {
      // Arrange
      final subject = design(label: '///', mimeType: 'image/png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert — never an empty name, which is a write that throws.
      expect(name, isNot(startsWith('.')));
      expect(name, endsWith('.png'));
    });
  });

  group('when there is nothing to save', () {
    test('a design with no link refuses without calling the network', () async {
      // Arrange — a row from an endpoint that did not load the signed URL.
      final subject = design(fileUrl: null);

      // Act
      final result = await save(subject);

      // Assert
      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.fileBytes(any()));
    });

    test('the server\'s own refusal is what comes back', () async {
      // Arrange — a signed link expires, and that is a 403 with a sentence on it.
      when(() => repository.fileBytes(any())).thenAnswer(
        (_) async => const Left(Failure.forbidden(message: 'انتهت صلاحية الرابط')),
      );

      // Act
      final result = await save(design());

      // Assert — not replaced with a generic message: the server said which refusal it was.
      expect(
        result.fold((failure) => failure.message, (_) => null),
        'انتهت صلاحية الرابط',
      );
    });

    test('the URL the screen is holding now is the one fetched', () async {
      // Arrange — links are signed per request, so a stored address is a 403 waiting to happen.
      // The fetch is made to fail on purpose: what this asserts is the *address*, and letting
      // it succeed would take the test into `path_provider`, which has no binding here and
      // would be testing that Dart can write a file.
      when(() => repository.fileBytes(any())).thenAnswer(
        (_) async => const Left(Failure.network(message: 'لا يوجد اتصال')),
      );
      final subject = design(fileUrl: 'https://files.example/x.png?signature=fresh');

      // Act
      await save(subject);

      // Assert
      verify(() => repository.fileBytes('https://files.example/x.png?signature=fresh')).called(1);
    });
  });
}
