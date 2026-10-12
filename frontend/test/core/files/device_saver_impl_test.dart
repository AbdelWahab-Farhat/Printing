import 'package:dayaa/core/files/device_saver.dart';
import 'package:dayaa/core/files/device_saver_impl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «تحميل» — أين ينتهي الملف على الهاتف، وما يحدث حين يرفض الهاتف المكان الأول.
///
/// الكتابة نفسها للإضافة ولا تعمل تحت `flutter_test`؛ ما لنا هنا هو **الترتيب**: الصورة إلى
/// «الصور» أولاً، وما يُرفض يُجرَّب في مكانٍ يقبله، ولا يصل صاحبَه خطأٌ ما دام للملف مكان.
///
/// Arrange - Act - Assert في كل اختبار.
class _MockFileSaver extends Mock implements FileSaver {}

void main() {
  late _MockFileSaver plugin;

  const path = '/tmp/designs/شعار المخبز.png';

  setUpAll(() {
    registerFallbackValue(MimeType.custom);
  });

  setUp(() {
    plugin = _MockFileSaver();
  });

  // نداءات الإضافة الأربعة بأسماء قصيرة، لأن كل اختبارٍ يحتاج أن يقول «هذا نجح» و«هذا رُفض».
  When<Future<String?>> gallery() => when(
    () => plugin.saveToGallery(
      name: any(named: 'name'),
      filePath: any(named: 'filePath'),
      includeExtension: any(named: 'includeExtension'),
      mimeType: any(named: 'mimeType'),
      customMimeType: any(named: 'customMimeType'),
    ),
  );

  When<Future<String?>> downloads() => when(
    () => plugin.saveToDownloads(
      name: any(named: 'name'),
      filePath: any(named: 'filePath'),
      includeExtension: any(named: 'includeExtension'),
      mimeType: any(named: 'mimeType'),
      customMimeType: any(named: 'customMimeType'),
    ),
  );

  When<Future<String>> documents() => when(
    () => plugin.saveFile(
      name: any(named: 'name'),
      filePath: any(named: 'filePath'),
      includeExtension: any(named: 'includeExtension'),
      mimeType: any(named: 'mimeType'),
      customMimeType: any(named: 'customMimeType'),
    ),
  );

  When<Future<String?>> dialog() => when(
    () => plugin.saveAs(
      name: any(named: 'name'),
      filePath: any(named: 'filePath'),
      includeExtension: any(named: 'includeExtension'),
      mimeType: any(named: 'mimeType'),
      customMimeType: any(named: 'customMimeType'),
    ),
  );

  final refused = PlatformException(code: 'PermissionDenied');

  group('صورة', () {
    test('تُحفظ في «الصور» باسمها كما هو', () async {
      // Arrange
      gallery().thenAnswer((_) async => 'content://media/external/images/media/7');
      final saver = DeviceSaverImpl(plugin: plugin, isIOS: false);

      // Act
      final result = await saver.toPhotos(path: path, mimeType: 'image/png');

      // Assert — الاسم كاملاً بامتداده، فلا تضيف الإضافة امتداداً ثانياً.
      expect(result.getOrElse(() => null), SavePlace.photos);
      verify(
        () => plugin.saveToGallery(
          name: 'شعار المخبز.png',
          filePath: path,
          includeExtension: false,
          mimeType: MimeType.custom,
          customMimeType: 'image/png',
        ),
      ).called(1);
    });

    test('على آيفون، ما ترفضه «الصور» يذهب إلى «الملفات»', () async {
      // Arrange — إذنٌ مُنع، أو صيغةٌ لا تقبلها مكتبة الصور: في الحالين للملف مكانٌ آخر.
      gallery().thenThrow(PlatformException(code: 'permission_denied'));
      documents().thenAnswer((_) async => '/Documents/شعار المخبز.png');
      final saver = DeviceSaverImpl(plugin: plugin, isIOS: true);

      // Act
      final result = await saver.toPhotos(path: path, mimeType: 'image/png');

      // Assert
      expect(result.getOrElse(() => null), SavePlace.files);
    });

    test('على أندرويد، ما ترفضه «الصور» يذهب إلى «التنزيلات»', () async {
      // Arrange
      gallery().thenThrow(refused);
      downloads().thenAnswer((_) async => 'content://media/external/downloads/9');
      final saver = DeviceSaverImpl(plugin: plugin, isIOS: false);

      // Act
      final result = await saver.toPhotos(path: path, mimeType: 'image/png');

      // Assert
      expect(result.getOrElse(() => null), SavePlace.downloads);
    });
  });

  group('ملف', () {
    const pdf = '/tmp/designs/شعار المخبز.pdf';

    test('على أندرويد يُحفظ في «التنزيلات»، ولا تُفتح نافذة', () async {
      // Arrange
      downloads().thenAnswer((_) async => 'content://media/external/downloads/9');
      final saver = DeviceSaverImpl(plugin: plugin, isIOS: false);

      // Act
      final result = await saver.toFiles(path: pdf, mimeType: 'application/pdf');

      // Assert
      expect(result.getOrElse(() => null), SavePlace.downloads);
      verify(
        () => plugin.saveToDownloads(
          name: 'شعار المخبز.pdf',
          filePath: pdf,
          includeExtension: false,
          mimeType: MimeType.custom,
          customMimeType: 'application/pdf',
        ),
      ).called(1);
      verifyNever(
        () => plugin.saveAs(
          name: any(named: 'name'),
          filePath: any(named: 'filePath'),
          includeExtension: any(named: 'includeExtension'),
          mimeType: any(named: 'mimeType'),
          customMimeType: any(named: 'customMimeType'),
        ),
      );
    });

    test('على آيفون يُحفظ في «الملفات»، فلا «تنزيلات» مشتركة هناك', () async {
      // Arrange
      documents().thenAnswer((_) async => '/Documents/شعار المخبز.pdf');
      final saver = DeviceSaverImpl(plugin: plugin, isIOS: true);

      // Act
      final result = await saver.toFiles(path: pdf, mimeType: 'application/pdf');

      // Assert
      expect(result.getOrElse(() => null), SavePlace.files);
      verifyNever(
        () => plugin.saveToDownloads(
          name: any(named: 'name'),
          filePath: any(named: 'filePath'),
          includeExtension: any(named: 'includeExtension'),
          mimeType: any(named: 'mimeType'),
          customMimeType: any(named: 'customMimeType'),
        ),
      );
    });

    test('أندرويد ٩ وما قبله بلا إذن تخزين: نافذة «حفظ باسم» من النظام', () async {
      // Arrange — هناك تحتاج «التنزيلات» إذناً، ونافذة النظام لا تحتاجه.
      downloads().thenThrow(refused);
      dialog().thenAnswer((_) async => 'content://com.android.externalstorage/document/1');
      final saver = DeviceSaverImpl(plugin: plugin, isIOS: false);

      // Act
      final result = await saver.toFiles(path: pdf, mimeType: 'application/pdf');

      // Assert
      expect(result.getOrElse(() => null), SavePlace.chosen);
    });

    test('من أغلق نافذة «حفظ باسم» لم يحفظ شيئاً، ولم يخطئ أحد', () async {
      // Arrange
      downloads().thenThrow(refused);
      dialog().thenAnswer((_) async => null);
      final saver = DeviceSaverImpl(plugin: plugin, isIOS: false);

      // Act
      final result = await saver.toFiles(path: pdf, mimeType: 'application/pdf');

      // Assert — `Right(null)`: لا إشعار نجاح ولا رسالة خطأ.
      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => SavePlace.photos), isNull);
    });

    test('حين لا يقبل الهاتف أي مكان، يعود خطأٌ يُعرض', () async {
      // Arrange
      documents().thenThrow(const FileSystemFullError());
      final saver = DeviceSaverImpl(plugin: plugin, isIOS: true);

      // Act
      final result = await saver.toFiles(path: pdf, mimeType: 'application/pdf');

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });
}

/// قرصٌ ممتلئ — أي رميةٍ من الإضافة لا نعرفها.
class FileSystemFullError implements Exception {
  const FileSystemFullError();
}
