import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/save_design_to_device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «تحميل» — اسمُ الملف حين يصل إلى الهاتف، وما يحدث حين لا يمكن جلبه أصلاً.
///
/// **الكتابة نفسها لا تُختبر هنا**: هي `File.writeAsBytes` في مجلدٍ يختاره النظام، واختبارٌ
/// يزيّف `path_provider` ليثبت أن Dart تكتب ملفاً لا يثبت شيئاً عن هذا التطبيق. ما لنا هو
/// الاسم والرفض. منقولٌ عن اختبار الصنف نفسه في تطبيق الموظفين.
///
/// Arrange - Act - Assert throughout.
class _MockDesignRepository extends Mock implements DesignRepository {}

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
    save = SaveDesignToDevice(repository);
  });

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
      // Arrange — الروابط تُوقَّع مع كل طلب، والجلب يُفشَل عمداً: ما يُختبر هو العنوان، ونجاحه
      // كان سيأخذ الاختبار إلى `path_provider` الذي لا ربط له هنا.
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
