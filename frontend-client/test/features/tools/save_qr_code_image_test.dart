import 'dart:io';

import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/features/designs/models/design_rules.dart';
import 'package:dayaa_client/features/tools/models/qr_code_art.dart';
import 'package:dayaa_client/features/tools/models/qr_ink.dart';
import 'package:dayaa_client/features/tools/usecases/save_qr_code_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// الملف الذي تأخذه ورقة المشاركة: أنه PNG فعلاً، وأن ضلعه يقبل القسمة على عدد الوحدات.
///
/// **الثانية هي التي تستحق اختباراً.** «صورة خرجت» يراها أول من يفتح الشاشة؛ أما أن كل وحدة
/// بنفس العرض تماماً فلا يظهر إلا على ماسحٍ يتردّد أمام رمزٍ مطبوع، وهو أبعد مكان يمكن أن
/// يُكتشف فيه خطأ.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Directory directory;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    directory = await Directory.systemTemp.createTemp('qr_tool_test');

    // `getTemporaryDirectory` نداءُ منصّة، ولا منصّة تحت `flutter test`.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => call.method == 'getTemporaryDirectory' ? directory.path : null,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await directory.delete(recursive: true);
  });

  test('يكتب ملف PNG باسم الموقع نفسه', () async {
    // Arrange
    final art = QrCodeArt.encode('https://daaya.ly');

    // Act
    final result = await const SaveQrCodeImage()(
      art: art,
      color: QrInk.black,
      transparentBackground: true,
    );

    // Assert
    final path = result.getOrElse(() => fail('لم يُكتب الملف: $result'));
    expect(path, endsWith('.png'));

    final bytes = await File(path).readAsBytes();
    // توقيع PNG: ‰PNG\r\n\x1a\n — لا امتداد اسمٍ فحسب.
    expect(bytes.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  });

  test('رمزان متتاليان ملفان مختلفان، فلا يكتب أحدهما فوق الآخر وهو يُرفع', () async {
    // Arrange
    final art = QrCodeArt.encode('https://daaya.ly');

    // Act
    final first = await const SaveQrCodeImage()(
      art: art,
      color: QrInk.black,
      transparentBackground: true,
    );
    final second = await const SaveQrCodeImage()(
      art: QrCodeArt.encode('0910000000'),
      color: QrInk.black,
      transparentBackground: true,
    );

    // Assert — الاسم المعروض واحد، والمسار على القرص ليس كذلك.
    final firstPath = first.getOrElse(() => fail('الأول لم يُكتب'));
    final secondPath = second.getOrElse(() => fail('الثاني لم يُكتب'));
    expect(firstPath, isNot(secondPath));
    expect(File(firstPath).existsSync(), isTrue);
    expect(SaveQrCodeImage.fileName, 'QR-Code.png');
  });

  test('الملف الخارج تقبله مكتبة تصاميم العميل كما هو', () async {
    // Arrange — الأداة تُخرج ملفاً، ومكتبة العميل هي من ترفعه: هذه هي البوّابة بينهما.
    final art = QrCodeArt.encode('https://daaya.ly');

    // Act
    final result = await const SaveQrCodeImage()(
      art: art,
      color: QrInk.black,
      transparentBackground: true,
    );
    final path = result.getOrElse(() => fail('لم يُكتب الملف'));
    final handed = PickedFile(
      path: path,
      name: SaveQrCodeImage.fileName,
      sizeBytes: File(path).lengthSync(),
    );

    // Assert — امتدادٌ مقبول وحجمٌ تحت السقف. لو خرج الملف بصيغةٍ لا تقبلها المكتبة لرُفض قبل
    // أن يُرسل، وهو فشلٌ لا يظهر إلا في يد الموظف بعد أن ينشئ رمزاً ويحاول إضافته.
    expect(DesignRules.reject(handed), isNull);
    expect(handed.sizeBytes, greaterThan(0));
  });

  test('ضلع الصورة مضاعفٌ صحيح لعدد الوحدات، قريبٌ من المقاس المطلوب', () async {
    // Arrange — أطوالٌ مختلفة، فأعدادُ وحداتٍ مختلفة، فمضاعفاتٌ مختلفة.
    for (final data in ['0910000000', 'https://daaya.ly', 'x' * 400]) {
      final art = QrCodeArt.encode(data);

      // Act
      final result = await const SaveQrCodeImage()(
        art: art,
        color: QrInk.black,
        transparentBackground: false,
      );

      // Assert — الضلع يقسم على الوحدات بلا باقٍ، فتخرج كل وحدة بنفس العرض بالضبط.
      final path = result.getOrElse(() => fail('لم يُكتب الملف لـ «$data»'));
      final side = await _sideOfPng(File(path));

      expect(side % art.canvasModules, isZero, reason: 'وحداتٌ متفاوتة العرض لـ «$data»');
      // ولا يبتعد عن المطلوب أكثر من وحدةٍ واحدة — وهو أقصى ما يمكن أن يقتطعه التقريب.
      expect(side, lessThanOrEqualTo(SaveQrCodeImage.targetSize));
      expect(
        side,
        greaterThan(SaveQrCodeImage.targetSize - art.canvasModules),
        reason: 'الصورة أصغر مما يبرّره التقريب لـ «$data»',
      );
    }
  });
}

/// عرض صورة PNG، من ترويسة `IHDR`: أربع بايتات كبيرة النهاية عند الإزاحة ١٦.
Future<int> _sideOfPng(File file) async {
  final bytes = await file.readAsBytes();

  return bytes.buffer.asByteData().getUint32(16);
}
