import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/device_saver.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_viewer.dart';
import 'package:dayaa/features/customers/usecases/save_design_to_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «تحميل» يحفظ ويقول أين — ولا يفتح ورقة المشاركة.
///
/// كل الأزرار التي تحمل «تحميل» (العارض، وخيارات التصميم، وتصاميم الطلبية) تنادي [saveDesign]،
/// فهو ما يُختبر هنا. وورقة المشاركة لا قناة لها تحت `flutter_test`: لو فُتحت لرمى الاختبار.
///
/// Arrange - Act - Assert في كل اختبار.
class _MockSaveDesign extends Mock implements SaveDesignToDevice {}

void main() {
  late _MockSaveDesign save;

  const design = CustomerDesign(
    id: 41,
    customerId: 3,
    label: 'شعار المخبز',
    kind: DesignKind.image,
    kindLabel: 'صورة',
    fileUrl: 'https://files.example/design.png?signature=abc',
  );

  setUpAll(() {
    registerFallbackValue(design);
  });

  setUp(() async {
    await Injector.reset();
    save = _MockSaveDesign();
    sl.registerSingleton<SaveDesignToDevice>(save);
  });

  tearDown(Injector.reset);

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => saveDesign(context, design),
            child: const Text('تحميل'),
          ),
        ),
      ),
    ),
  );

  Future<void> tapDownload(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('تحميل'));
    await tester.pumpAndSettle();
  }

  // الإشعار يحمل مؤقّت إخفاءٍ لثلاث ثوانٍ، ومؤقّتٌ باقٍ بعد هدم الشجرة يُفشل الاختبار.
  Future<void> letTheToastGo(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  const said = {
    SavePlace.photos: 'حُفظ التصميم في الصور',
    SavePlace.downloads: 'حُفظ التصميم في التنزيلات',
    SavePlace.files: 'حُفظ التصميم في «الملفات»',
    SavePlace.chosen: 'حُفظ التصميم',
  };

  for (final MapEntry(key: place, value: message) in said.entries) {
    testWidgets('حين يُحفظ في ${place.name} يقول «$message»', (tester) async {
      // Arrange
      when(() => save(any())).thenAnswer((_) async => Right(place));

      // Act
      await tapDownload(tester);

      // Assert
      verify(() => save(design)).called(1);
      expect(find.text(message), findsOneWidget);

      await letTheToastGo(tester);
    });
  }

  testWidgets('من أغلق نافذة «حفظ باسم» لا يرى شيئاً', (tester) async {
    // Arrange
    when(() => save(any())).thenAnswer((_) async => const Right(null));

    // Act
    await tapDownload(tester);

    // Assert — لا نجاح يُدّعى ولا خطأ يُخترع.
    expect(find.textContaining('حُفظ'), findsNothing);
  });

  testWidgets('ما رفضه الخادم أو الهاتف يُعرض بكلماته', (tester) async {
    // Arrange
    when(() => save(any())).thenAnswer(
      (_) async => const Left(Failure.forbidden(message: 'انتهت صلاحية الرابط')),
    );

    // Act
    await tapDownload(tester);

    // Assert
    expect(find.text('انتهت صلاحية الرابط'), findsOneWidget);

    await letTheToastGo(tester);
  });
}
