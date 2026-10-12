import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/device_saver.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/save_design_to_device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «تحميل» — اسمُ الملف حين يصل إلى الهاتف، وأين يذهب، وما يحدث حين لا يمكن جلبه أصلاً.
///
/// الحفظ نفسه خلف [DeviceSaver] (اختباره في `core/files`)؛ ما لهذا الصنف هو الاسم، والنوع،
/// واختيار المكان: الصورة إلى «الصور» وما سواها إلى «التنزيلات» / «الملفات». منقولٌ عن اختبار
/// الصنف نفسه في تطبيق الموظفين.
///
/// Arrange - Act - Assert throughout.
class _MockDesignRepository extends Mock implements DesignRepository {}

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
      label: label,
      kind: kind,
      kindLabel: kind == DesignKind.pdf ? 'PDF' : 'صورة',
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

  group('اسم الملف المحفوظ', () {
    test('اسم التصميم هو اسم الملف، فيُعثر عليه بعدها', () {
      // Arrange
      final subject = design(originalFilename: 'IMG_2231.png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert — «IMG_2231.png» اسمٌ لا يعرفه أحدٌ في تطبيق الملفات بعد أسبوع.
      expect(name, 'شعار المخبز.png');
    });

    test('امتداد الملف الأصلي يسبق نوعه', () {
      // Arrange — المطبعة تنتظر الملف الذي أرسله العميل، و.jpg يُحفظ .png ملفٌ ترفضه أدوات.
      final subject = design(originalFilename: 'logo.JPG', mimeType: 'image/png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert
      expect(name, 'شعار المخبز.jpg');
    });

    test('ملف PDF يبقى PDF', () {
      // Arrange
      final subject = design(kind: DesignKind.pdf, mimeType: 'application/pdf');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert
      expect(name, 'شعار المخبز.pdf');
    });

    test('اسمٌ هو اسم الملف أصلاً لا يُعطى امتداداً ثانياً', () {
      // Arrange
      final subject = design(label: 'شعار.png', mimeType: 'image/png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert
      expect(name, 'شعار.png');
    });

    test('الشَّرطة المائلة في الاسم لا تصير مجلداً', () {
      // Arrange — «شعار 2024/2025» اسمٌ سيُكتب، وفاصل مسارٍ فيه كتابةٌ تفشل بخطأٍ لا يُفهم.
      final subject = design(label: 'شعار 2024/2025', mimeType: 'image/png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert
      expect(name, 'شعار 2024-2025.png');
    });

    test('اسمٌ كلّه علامات يبقى له اسم ملف', () {
      // Arrange
      final subject = design(label: '///', mimeType: 'image/png');

      // Act
      final name = SaveDesignToDevice.fileNameFor(subject);

      // Assert — لا اسمَ فارغاً أبداً، فهو كتابةٌ ترمي خطأً.
      expect(name, isNot(startsWith('.')));
      expect(name, endsWith('.png'));
    });
  });

  group('حين لا يوجد ما يُحفظ', () {
    test('تصميمٌ بلا رابط يُرفض دون طلبٍ إلى الشبكة', () async {
      // Arrange
      final subject = design(fileUrl: null);

      // Act
      final result = await save(subject);

      // Assert
      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.fileBytes(any()));
    });

    test('رفض الخادم نفسه هو ما يعود', () async {
      // Arrange — الرابط الموقَّع تنتهي صلاحيته، وذاك ٤٠٣ عليه جملته.
      when(() => repository.fileBytes(any())).thenAnswer(
        (_) async => const Left(Failure.forbidden(message: 'انتهت صلاحية الرابط')),
      );

      // Act
      final result = await save(design());

      // Assert — لا تُستبدل برسالةٍ عامة: الخادم قال أيّ رفضٍ هو.
      expect(result.fold((failure) => failure.message, (_) => null), 'انتهت صلاحية الرابط');
    });

    test('الرابط الذي تحمله الشاشة الآن هو الذي يُجلب', () async {
      // Arrange — الروابط تُوقَّع مع كل طلب، والجلب يُفشَل عمداً: ما يُختبر هو العنوان.
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

  group('أين يذهب', () {
    test('الصورة إلى «الصور»، باسمها ونوعها', () async {
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

    test('الـPDF إلى «التنزيلات» / «الملفات»، لا إلى «الصور»', () async {
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

    test('النوع يتبع الامتداد الذي يُحفظ به الملف', () async {
      // Arrange — ملفٌّ اسمه .jpg بنوع image/png يقرؤه المعرض بغير ما هو؛ الامتداد هو ما يبقى.
      fileArrives();

      // Act
      await save(design(originalFilename: 'logo.JPG', mimeType: 'image/png'));

      // Assert
      verify(
        () => saver.toPhotos(path: '${temp.path}/شعار المخبز.jpg', mimeType: 'image/jpeg'),
      ).called(1);
    });

    test('صورة webp صورةٌ أيضاً', () async {
      // Arrange
      fileArrives();

      // Act
      await save(design(originalFilename: 'logo.webp'));

      // Assert
      verify(
        () => saver.toPhotos(path: '${temp.path}/شعار المخبز.webp', mimeType: 'image/webp'),
      ).called(1);
    });

    test('رفض الهاتف هو ما يعود', () async {
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

    test('تصميمٌ لم يُجلب لا يصل إلى ذاكرة الهاتف', () async {
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
}
