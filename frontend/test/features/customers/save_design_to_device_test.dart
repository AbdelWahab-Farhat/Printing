import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/device_saver.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';
import 'package:dayaa/features/customers/usecases/save_design_to_device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «تحميل» — ما اسم الملف حين يصل الهاتف، وأين يذهب، وما يحدث حين لا يُجلب أصلاً.
///
/// الحفظ نفسه خلف [DeviceSaver] (اختباره في `core/files`)؛ ما لهذا الصنف هو الاسم، والنوع،
/// واختيار المكان: الصورة إلى «الصور» وما سواها إلى «التنزيلات» / «الملفات».
///
/// Arrange - Act - Assert في كل اختبار.
class _MockDesignRepository extends Mock implements CustomerDesignRepository {}

class _MockDeviceSaver extends Mock implements DeviceSaver {}

void main() {
  late _MockDesignRepository repository;
  late _MockDeviceSaver saver;
  late Directory temp;
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
    saver = _MockDeviceSaver();
    temp = Directory.systemTemp.createTempSync('save-design-test-');
    save = SaveDesignToDevice(repository, saver, temporaryDirectory: () async => temp);
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
  });

  // البايتات تصل، والهاتف يقبل المكان الذي يُطلب منه — ما يختلف بين الاختبارات هو التصميم.
  void fileArrives() {
    when(() => repository.fileBytes(any())).thenAnswer(
      (_) async => Right(Uint8List.fromList([1, 2, 3])),
    );
    when(
      () => saver.toPhotos(path: any(named: 'path'), mimeType: any(named: 'mimeType')),
    ).thenAnswer((_) async => const Right(SavePlace.photos));
    when(
      () => saver.toFiles(path: any(named: 'path'), mimeType: any(named: 'mimeType')),
    ).thenAnswer((_) async => const Right(SavePlace.downloads));
  }

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
      // The fetch is made to fail on purpose: what this asserts is the *address*.
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

  group('where it goes', () {
    test('an image goes to «الصور», named and typed', () async {
      // Arrange
      fileArrives();

      // Act
      final result = await save(design(mimeType: 'image/png'));

      // Assert — الصورة تُحفظ حيث تُحفظ الصور، لا ورقة مشاركة.
      expect(result.getOrElse(() => null), SavePlace.photos);
      verify(
        () => saver.toPhotos(path: '${temp.path}/شعار المخبز.png', mimeType: 'image/png'),
      ).called(1);
    });

    test('a PDF goes to «التنزيلات» / «الملفات», not to «الصور»', () async {
      // Arrange — مكتبة الصور لا تقبل PDF على المنصّتين.
      fileArrives();

      // Act
      final result = await save(design(kind: DesignKind.pdf, mimeType: 'application/pdf'));

      // Assert
      expect(result.getOrElse(() => null), SavePlace.downloads);
      verify(
        () => saver.toFiles(path: '${temp.path}/شعار المخبز.pdf', mimeType: 'application/pdf'),
      ).called(1);
      verifyNever(
        () => saver.toPhotos(path: any(named: 'path'), mimeType: any(named: 'mimeType')),
      );
    });

    test('the type follows the extension the file is saved with', () async {
      // Arrange — ملفٌّ اسمه .jpg بنوع image/png يقرؤه المعرض بغير ما هو؛ الامتداد هو ما يبقى.
      fileArrives();

      // Act
      await save(design(originalFilename: 'logo.JPG', mimeType: 'image/png'));

      // Assert
      verify(
        () => saver.toPhotos(path: '${temp.path}/شعار المخبز.jpg', mimeType: 'image/jpeg'),
      ).called(1);
    });

    test('a webp is still a picture', () async {
      // Arrange
      fileArrives();

      // Act
      await save(design(originalFilename: 'logo.webp'));

      // Assert
      verify(
        () => saver.toPhotos(path: '${temp.path}/شعار المخبز.webp', mimeType: 'image/webp'),
      ).called(1);
    });

    test('the phone\'s refusal is what comes back', () async {
      // Arrange
      fileArrives();
      when(
        () => saver.toPhotos(path: any(named: 'path'), mimeType: any(named: 'mimeType')),
      ).thenAnswer((_) async => const Left(Failure.unexpected(message: 'تعذّر حفظ التصميم')));

      // Act
      final result = await save(design(mimeType: 'image/png'));

      // Assert
      expect(result.fold((failure) => failure.message, (_) => null), 'تعذّر حفظ التصميم');
    });

    test('a design that could not be fetched never reaches the phone\'s storage', () async {
      // Arrange
      fileArrives();
      when(() => repository.fileBytes(any())).thenAnswer(
        (_) async => const Left(Failure.network(message: 'لا يوجد اتصال')),
      );

      // Act
      final result = await save(design());

      // Assert
      expect(result.isLeft(), isTrue);
      verifyNever(
        () => saver.toPhotos(path: any(named: 'path'), mimeType: any(named: 'mimeType')),
      );
      verifyNever(
        () => saver.toFiles(path: any(named: 'path'), mimeType: any(named: 'mimeType')),
      );
    });
  });

  group('fetching for the bag preview', () {
    test('the file is written to the temp directory and its path returned', () async {
      // Arrange — المعاينة ترسم الملف، فتحتاج مساره لا مكاناً في «الصور».
      fileArrives();

      // Act
      final result = await save.fetch(design(mimeType: 'image/png'));

      // Assert
      final path = result.getOrElse(() => '');
      expect(path, '${temp.path}/شعار المخبز.png');
      expect(File(path).readAsBytesSync(), [1, 2, 3]);
      verifyNever(
        () => saver.toPhotos(path: any(named: 'path'), mimeType: any(named: 'mimeType')),
      );
    });
  });
}
